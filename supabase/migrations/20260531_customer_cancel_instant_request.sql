-- Customer cancel instant request: atomic cancel + expire all open worker offers.

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
        'expired',
        'customer_cancelled'
    ));

-- ---------------------------------------------------------------------------
-- Customer cancels a pending instant direct-worker request
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.customer_cancel_instant_request(
    p_request_id UUID,
    p_customer_id UUID,
    p_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_auth_customer_id UUID := auth.uid();
    v_request public.service_requests;
    v_offers_cancelled INT := 0;
BEGIN
    IF v_auth_customer_id IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;

    IF p_customer_id IS DISTINCT FROM v_auth_customer_id THEN
        RAISE EXCEPTION 'forbidden';
    END IF;

    SELECT * INTO v_request
    FROM public.service_requests
    WHERE id = p_request_id
      AND customer_id = p_customer_id
      AND booking_type = 'instant'
      AND request_flow = 'direct_worker';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'invalid_request';
    END IF;

    IF v_request.status <> 'pending' THEN
        IF v_request.status IN (
            'accepted',
            'worker_on_the_way',
            'arrived',
            'in_progress',
            'bill_generated'
        ) THEN
            RAISE EXCEPTION 'worker_already_assigned';
        END IF;
        RAISE EXCEPTION 'request_not_cancellable';
    END IF;

    UPDATE public.service_requests
    SET
        status = 'cancelled',
        cancellation_reason = NULLIF(TRIM(p_reason), ''),
        updated_at = NOW()
    WHERE id = p_request_id
      AND customer_id = p_customer_id
      AND status = 'pending';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'request_already_cancelled';
    END IF;

    UPDATE public.request_worker_offers
    SET
        status = 'customer_cancelled',
        responded_at = NOW()
    WHERE request_id = p_request_id
      AND status IN ('sent', 'accepted_by_worker', 'counter_offer');

    GET DIAGNOSTICS v_offers_cancelled = ROW_COUNT;

    RETURN jsonb_build_object(
        'success', true,
        'request_id', p_request_id,
        'offers_cancelled_count', v_offers_cancelled
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.customer_cancel_instant_request(UUID, UUID, TEXT) TO authenticated;
