-- Scheduled job overdue / no-show / reassigned statuses for service_requests

ALTER TABLE public.service_requests
    DROP CONSTRAINT IF EXISTS service_requests_status_check;

ALTER TABLE public.service_requests
    ADD CONSTRAINT service_requests_status_check
    CHECK (status IN (
        'pending',
        'pending_admin_approval',
        'approved',
        'assigned',
        'accepted',
        'worker_on_the_way',
        'arrived',
        'in_progress',
        'work_submitted',
        'bill_generated',
        'paid',
        'completed',
        'cancelled',
        'rejected',
        'overdue',
        'worker_no_show',
        'reassigned'
    ));
