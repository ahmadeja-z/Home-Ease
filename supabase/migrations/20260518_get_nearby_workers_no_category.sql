-- Run in Supabase SQL Editor: show ALL online workers within radius (no category filter)

DROP FUNCTION IF EXISTS public.get_nearby_workers(
    DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, TEXT
);

CREATE OR REPLACE FUNCTION public.get_nearby_workers(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_km DOUBLE PRECISION DEFAULT 10.0
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
    DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION
) TO authenticated;
