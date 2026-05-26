-- Scheduled service booking columns on service_requests
ALTER TABLE public.service_requests
    ADD COLUMN IF NOT EXISTS service_id BIGINT REFERENCES public.services(id),
    ADD COLUMN IF NOT EXISTS customer_request_images JSONB DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS scheduled_time TIMESTAMPTZ;
