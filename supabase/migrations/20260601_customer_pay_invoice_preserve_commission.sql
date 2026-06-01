-- Preserve commission fields set at bill generation; do not recalculate on payment.

CREATE OR REPLACE FUNCTION public.customer_pay_invoice(p_request_id UUID)
RETURNS public.service_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_customer_id UUID := auth.uid();
    v_request public.service_requests;
    v_final_amount DOUBLE PRECISION;
BEGIN
    IF v_customer_id IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;

    SELECT sr.final_amount
    INTO v_final_amount
    FROM public.service_requests sr
    WHERE sr.id = p_request_id
      AND sr.customer_id = v_customer_id
      AND sr.status = 'bill_generated'
      AND sr.payment_status = 'unpaid'
      AND COALESCE(sr.final_amount, 0) > 0;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'invalid_request_for_payment';
    END IF;

    UPDATE public.service_requests sr
    SET
        payment_status = 'paid',
        status = 'completed',
        completed_at = NOW(),
        customer_paid_amount = v_final_amount,
        customer_paid_at = NOW(),
        commission_status = CASE
            WHEN sr.platform_commission IS NOT NULL
              OR sr.worker_earning IS NOT NULL
              OR COALESCE(sr.platform_fee, 0) > 0
            THEN 'pending'
            ELSE sr.commission_status
        END,
        updated_at = NOW()
    WHERE sr.id = p_request_id
      AND sr.customer_id = v_customer_id
      AND sr.status = 'bill_generated'
      AND sr.payment_status = 'unpaid'
      AND COALESCE(sr.final_amount, 0) > 0
    RETURNING * INTO v_request;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'invalid_request_for_payment';
    END IF;

    RETURN v_request;
END;
$$;

GRANT EXECUTE ON FUNCTION public.customer_pay_invoice(UUID) TO authenticated;
