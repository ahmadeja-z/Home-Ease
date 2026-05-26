-- Instant booking: request_worker_offers, category-filtered workers RPC,
-- atomic accept, RLS, and realtime.

-- ---------------------------------------------------------------------------
-- service_requests columns (if missing from older setup)
-- ---------------------------------------------------------------------------
ALTER TABLE public.service_requests
    ADD COLUMN IF NOT EXISTS booking_type TEXT DEFAULT 'instant',
    ADD COLUMN IF NOT EXISTS request_flow TEXT DEFAULT 'direct_worker',
    ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'unpaid',
    ADD COLUMN IF NOT EXISTS final_amount DOUBLE PRECISION DEFAULT 0,
    ADD COLUMN IF NOT EXISTS preferred_date DATE,
    ADD COLUMN IF NOT EXISTS preferred_time TEXT,
    ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS arrived_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS started_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS payment_method TEXT;

-- ---------------------------------------------------------------------------
-- request_worker_offers
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.request_worker_offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
    worker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'sent'
        CHECK (status IN ('sent', 'accepted', 'rejected', 'expired')),
    offered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    responded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (request_id, worker_id)
);

CREATE INDEX IF NOT EXISTS idx_request_worker_offers_request_id
    ON public.request_worker_offers(request_id);
CREATE INDEX IF NOT EXISTS idx_request_worker_offers_worker_id
    ON public.request_worker_offers(worker_id);
CREATE INDEX IF NOT EXISTS idx_request_worker_offers_status
    ON public.request_worker_offers(status);

ALTER TABLE public.request_worker_offers ENABLE ROW LEVEL SECURITY;

-- Customers: create offers for their own pending requests (via app after insert)
DROP POLICY IF EXISTS "Customers insert offers for own requests" ON public.request_worker_offers;
CREATE POLICY "Customers insert offers for own requests"
    ON public.request_worker_offers FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.service_requests sr
            WHERE sr.id = request_id
              AND sr.customer_id = auth.uid()
              AND sr.status = 'pending'
        )
    );

-- Customers: read offers for their requests
DROP POLICY IF EXISTS "Customers read offers for own requests" ON public.request_worker_offers;
CREATE POLICY "Customers read offers for own requests"
    ON public.request_worker_offers FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.service_requests sr
            WHERE sr.id = request_id AND sr.customer_id = auth.uid()
        )
    );

-- Workers: read their offers
DROP POLICY IF EXISTS "Workers read own offers" ON public.request_worker_offers;
CREATE POLICY "Workers read own offers"
    ON public.request_worker_offers FOR SELECT
    USING (auth.uid() = worker_id);

-- Workers: update their own offers (reject / accept via RPC still allowed for accept)
DROP POLICY IF EXISTS "Workers update own offers" ON public.request_worker_offers;
CREATE POLICY "Workers update own offers"
    ON public.request_worker_offers FOR UPDATE
    USING (auth.uid() = worker_id)
    WITH CHECK (auth.uid() = worker_id);

-- Workers: read service_requests they have an offer for
DROP POLICY IF EXISTS "Workers read requests with offers" ON public.service_requests;
CREATE POLICY "Workers read requests with offers"
    ON public.service_requests FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.request_worker_offers o
            WHERE o.request_id = service_requests.id
              AND o.worker_id = auth.uid()
        )
        OR auth.uid() = worker_id
    );

-- Workers: update assigned requests (status progression after accept)
DROP POLICY IF EXISTS "Workers update assigned requests" ON public.service_requests;
CREATE POLICY "Workers update assigned requests"
    ON public.service_requests FOR UPDATE
    USING (auth.uid() = worker_id);

-- ---------------------------------------------------------------------------
-- get_nearby_workers with optional category filter
-- ---------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.get_nearby_workers(
    DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, TEXT
);
DROP FUNCTION IF EXISTS public.get_nearby_workers(
    DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION
);

CREATE OR REPLACE FUNCTION public.get_nearby_workers(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_km DOUBLE PRECISION DEFAULT 10.0,
    category_id TEXT DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    profile_picture TEXT,
    rating DOUBLE PRECISION,
    distance DOUBLE PRECISION,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_online BOOLEAN,
    category_id TEXT,
    category_name TEXT,
    per_hour_rate DOUBLE PRECISION,
    completed_jobs INTEGER
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.name,
        p.profile_picture,
        COALESCE(p.rating, 0.0)::DOUBLE PRECISION AS rating,
        (
            6371 * acos(
                LEAST(1.0, GREATEST(-1.0,
                    cos(radians(user_lat)) *
                    cos(radians(wl.latitude)) *
                    cos(radians(wl.longitude) - radians(user_lng)) +
                    sin(radians(user_lat)) *
                    sin(radians(wl.latitude))
                ))
            )
        )::DOUBLE PRECISION AS distance,
        wl.latitude,
        wl.longitude,
        wl.is_online,
        wl.category_id,
        wl.category_name,
        wl.per_hour_rate,
        wl.completed_jobs
    FROM public.worker_locations wl
    INNER JOIN public.profiles p ON p.id = wl.worker_id
    WHERE
        p.role = 'worker'
        AND p.status = 'approved'
        AND COALESCE(p.is_active, true) = true
        AND wl.is_online = true
        AND wl.latitude IS NOT NULL
        AND wl.longitude IS NOT NULL
        AND (
            get_nearby_workers.category_id IS NULL
            OR wl.category_id = get_nearby_workers.category_id
        )
        AND (
            6371 * acos(
                LEAST(1.0, GREATEST(-1.0,
                    cos(radians(user_lat)) *
                    cos(radians(wl.latitude)) *
                    cos(radians(wl.longitude) - radians(user_lng)) +
                    sin(radians(user_lat)) *
                    sin(radians(wl.latitude))
                ))
            )
        ) <= radius_km
    ORDER BY distance ASC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_nearby_workers(
    DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, TEXT
) TO authenticated;

-- ---------------------------------------------------------------------------
-- Atomic accept: first worker wins
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.accept_instant_request(
    p_request_id UUID,
    p_offer_id UUID
)
RETURNS public.service_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_worker_id UUID := auth.uid();
    v_request public.service_requests;
    v_worker_lat DOUBLE PRECISION;
    v_worker_lng DOUBLE PRECISION;
    v_profile RECORD;
BEGIN
    IF v_worker_id IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;

    SELECT * INTO v_profile
    FROM public.profiles
    WHERE id = v_worker_id;

    IF NOT FOUND OR v_profile.role <> 'worker' THEN
        RAISE EXCEPTION 'not_a_worker';
    END IF;

    SELECT latitude, longitude
    INTO v_worker_lat, v_worker_lng
    FROM public.worker_locations
    WHERE worker_id = v_worker_id;

    UPDATE public.service_requests sr
    SET
        worker_id = v_worker_id,
        worker_name = v_profile.name,
        worker_phone = v_profile.phone_number,
        worker_profile_picture = v_profile.profile_picture,
        worker_rating = v_profile.rating,
        worker_latitude = v_worker_lat,
        worker_longitude = v_worker_lng,
        status = 'accepted',
        accepted_at = NOW(),
        updated_at = NOW()
    WHERE sr.id = p_request_id
      AND sr.status = 'pending'
    RETURNING * INTO v_request;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'request_already_accepted';
    END IF;

    UPDATE public.request_worker_offers
    SET status = 'accepted', responded_at = NOW()
    WHERE id = p_offer_id
      AND worker_id = v_worker_id
      AND request_id = p_request_id
      AND status = 'sent';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'invalid_offer';
    END IF;

    UPDATE public.request_worker_offers
    SET status = 'expired', responded_at = NOW()
    WHERE request_id = p_request_id
      AND id <> p_offer_id
      AND status = 'sent';

    RETURN v_request;
END;
$$;

GRANT EXECUTE ON FUNCTION public.accept_instant_request(UUID, UUID) TO authenticated;

-- ---------------------------------------------------------------------------
-- Realtime
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.request_worker_offers;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.service_requests;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;
