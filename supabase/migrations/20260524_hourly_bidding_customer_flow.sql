-- Hourly bidding: pricing columns, offer fields, extended statuses, customer/worker RPCs.

-- service_requests pricing & billing
ALTER TABLE public.service_requests
    ADD COLUMN IF NOT EXISTS pricing_type TEXT DEFAULT 'hourly',
    ADD COLUMN IF NOT EXISTS base_price DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS accepted_price DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS labor_charges DOUBLE PRECISION DEFAULT 0,
    ADD COLUMN IF NOT EXISTS material_charges DOUBLE PRECISION DEFAULT 0,
    ADD COLUMN IF NOT EXISTS platform_fee DOUBLE PRECISION DEFAULT 0,
    ADD COLUMN IF NOT EXISTS total_hours DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS worker_completion_note TEXT,
    ADD COLUMN IF NOT EXISTS completion_images JSONB DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS bill_generated_at TIMESTAMPTZ;

-- request_worker_offers bidding fields
ALTER TABLE public.request_worker_offers
    ADD COLUMN IF NOT EXISTS offered_price DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS worker_message TEXT,
    ADD COLUMN IF NOT EXISTS offer_type TEXT DEFAULT 'base_price';

-- Expand offer status values (drop old check if present)
ALTER TABLE public.request_worker_offers
    DROP CONSTRAINT IF EXISTS request_worker_offers_status_check;

ALTER TABLE public.request_worker_offers
    ADD CONSTRAINT request_worker_offers_status_check
    CHECK (status IN (
        'sent',
        'accepted',
        'accepted_by_worker',
        'counter_offer',
        'customer_accepted',
        'rejected',
        'expired'
    ));

-- ---------------------------------------------------------------------------
-- Worker accepts customer base price (does NOT assign worker yet)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.worker_accept_base_price(p_offer_id UUID)
RETURNS public.request_worker_offers
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_worker_id UUID := auth.uid();
    v_offer public.request_worker_offers;
    v_base_price DOUBLE PRECISION;
BEGIN
    IF v_worker_id IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;

    SELECT o.* INTO v_offer
    FROM public.request_worker_offers o
    JOIN public.service_requests sr ON sr.id = o.request_id
    WHERE o.id = p_offer_id
      AND o.worker_id = v_worker_id
      AND o.status = 'sent'
      AND sr.status = 'pending';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'invalid_offer';
    END IF;

    SELECT sr.base_price INTO v_base_price
    FROM public.service_requests sr
    WHERE sr.id = v_offer.request_id;

    UPDATE public.request_worker_offers
    SET
        status = 'accepted_by_worker',
        offered_price = v_base_price,
        offer_type = 'base_price',
        responded_at = NOW()
    WHERE id = p_offer_id
    RETURNING * INTO v_offer;

    RETURN v_offer;
END;
$$;

GRANT EXECUTE ON FUNCTION public.worker_accept_base_price(UUID) TO authenticated;

-- ---------------------------------------------------------------------------
-- Worker counter-offer (per-hour price + optional message)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.worker_counter_offer(
    p_offer_id UUID,
    p_offered_price DOUBLE PRECISION,
    p_worker_message TEXT DEFAULT NULL
)
RETURNS public.request_worker_offers
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_worker_id UUID := auth.uid();
    v_offer public.request_worker_offers;
BEGIN
    IF v_worker_id IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;

    IF p_offered_price IS NULL OR p_offered_price <= 0 THEN
        RAISE EXCEPTION 'invalid_price';
    END IF;

    SELECT o.* INTO v_offer
    FROM public.request_worker_offers o
    JOIN public.service_requests sr ON sr.id = o.request_id
    WHERE o.id = p_offer_id
      AND o.worker_id = v_worker_id
      AND o.status = 'sent'
      AND sr.status = 'pending';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'invalid_offer';
    END IF;

    UPDATE public.request_worker_offers
    SET
        status = 'counter_offer',
        offered_price = p_offered_price,
        offer_type = 'counter',
        worker_message = p_worker_message,
        responded_at = NOW()
    WHERE id = p_offer_id
    RETURNING * INTO v_offer;

    RETURN v_offer;
END;
$$;

GRANT EXECUTE ON FUNCTION public.worker_counter_offer(UUID, DOUBLE PRECISION, TEXT) TO authenticated;

-- ---------------------------------------------------------------------------
-- Customer accepts one worker offer (assigns worker on service_requests)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.customer_accept_worker_offer(
    p_offer_id UUID,
    p_request_id UUID
)
RETURNS public.service_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_customer_id UUID := auth.uid();
    v_offer public.request_worker_offers;
    v_request public.service_requests;
    v_profile RECORD;
    v_worker_lat DOUBLE PRECISION;
    v_worker_lng DOUBLE PRECISION;
BEGIN
    IF v_customer_id IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;

    SELECT o.* INTO v_offer
    FROM public.request_worker_offers o
    JOIN public.service_requests sr ON sr.id = o.request_id
    WHERE o.id = p_offer_id
      AND o.request_id = p_request_id
      AND sr.customer_id = v_customer_id
      AND sr.status = 'pending'
      AND o.status IN ('accepted_by_worker', 'counter_offer');

    IF NOT FOUND THEN
        RAISE EXCEPTION 'invalid_offer';
    END IF;

    SELECT * INTO v_profile
    FROM public.profiles
    WHERE id = v_offer.worker_id;

    SELECT latitude, longitude
    INTO v_worker_lat, v_worker_lng
    FROM public.worker_locations
    WHERE worker_id = v_offer.worker_id;

    UPDATE public.service_requests sr
    SET
        worker_id = v_offer.worker_id,
        worker_name = v_profile.name,
        worker_phone = v_profile.phone_number,
        worker_profile_picture = v_profile.profile_picture,
        worker_rating = v_profile.rating,
        worker_latitude = v_worker_lat,
        worker_longitude = v_worker_lng,
        accepted_price = v_offer.offered_price,
        status = 'accepted',
        accepted_at = NOW(),
        updated_at = NOW()
    WHERE sr.id = p_request_id
      AND sr.customer_id = v_customer_id
      AND sr.status = 'pending'
    RETURNING * INTO v_request;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'request_already_accepted';
    END IF;

    UPDATE public.request_worker_offers
    SET status = 'customer_accepted', responded_at = NOW()
    WHERE id = p_offer_id;

    UPDATE public.request_worker_offers
    SET status = 'expired', responded_at = NOW()
    WHERE request_id = p_request_id
      AND id <> p_offer_id
      AND status IN ('sent', 'accepted_by_worker', 'counter_offer');

    RETURN v_request;
END;
$$;

GRANT EXECUTE ON FUNCTION public.customer_accept_worker_offer(UUID, UUID) TO authenticated;

-- ---------------------------------------------------------------------------
-- Customer pays invoice → completed (only after bill_generated)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.customer_pay_invoice(p_request_id UUID)
RETURNS public.service_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_customer_id UUID := auth.uid();
    v_request public.service_requests;
BEGIN
    IF v_customer_id IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;

    UPDATE public.service_requests sr
    SET
        payment_status = 'paid',
        status = 'completed',
        completed_at = NOW(),
        updated_at = NOW()
    WHERE sr.id = p_request_id
      AND sr.customer_id = v_customer_id
      AND sr.status = 'bill_generated'
      AND sr.payment_status = 'unpaid'
    RETURNING * INTO v_request;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'invalid_request_for_payment';
    END IF;

    RETURN v_request;
END;
$$;

GRANT EXECUTE ON FUNCTION public.customer_pay_invoice(UUID) TO authenticated;

-- Customers may update own requests when accepting offers (RPC uses SECURITY DEFINER)
DROP POLICY IF EXISTS "Customers update own pending requests" ON public.service_requests;
CREATE POLICY "Customers update own pending requests"
    ON public.service_requests FOR UPDATE
    USING (auth.uid() = customer_id);
