# Supabase Database Setup for Map Requests Module

You need to run these SQL commands in your Supabase SQL Editor to create the required tables and functions.

## 1. Create Service Requests Table

```sql
-- Create service_requests table
CREATE TABLE IF NOT EXISTS public.service_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    worker_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    category_id TEXT NOT NULL,
    category_name TEXT,
    customer_latitude DOUBLE PRECISION NOT NULL,
    customer_longitude DOUBLE PRECISION NOT NULL,
    customer_address TEXT NOT NULL,
    worker_latitude DOUBLE PRECISION,
    worker_longitude DOUBLE PRECISION,
    worker_name TEXT,
    worker_profile_picture TEXT,
    worker_rating DOUBLE PRECISION,
    worker_phone TEXT,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'worker_on_the_way', 'arrived', 'in_progress', 'completed', 'cancelled')),
    type TEXT NOT NULL DEFAULT 'immediate' CHECK (type IN ('immediate', 'scheduled')),
    estimated_price DOUBLE PRECISION,
    scheduled_time TIMESTAMPTZ,
    review TEXT,
    rating DOUBLE PRECISION,
    cancellation_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    completed_at TIMESTAMPTZ
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_service_requests_customer_id ON public.service_requests(customer_id);
CREATE INDEX IF NOT EXISTS idx_service_requests_worker_id ON public.service_requests(worker_id);
CREATE INDEX IF NOT EXISTS idx_service_requests_status ON public.service_requests(status);
CREATE INDEX IF NOT EXISTS idx_service_requests_category_id ON public.service_requests(category_id);
CREATE INDEX IF NOT EXISTS idx_service_requests_created_at ON public.service_requests(created_at DESC);

-- Enable Row Level Security
ALTER TABLE public.service_requests ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Customers can view their own requests"
    ON public.service_requests FOR SELECT
    USING (auth.uid() = customer_id);

CREATE POLICY "Customers can create requests"
    ON public.service_requests FOR INSERT
    WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Customers can update their own requests"
    ON public.service_requests FOR UPDATE
    USING (auth.uid() = customer_id);

CREATE POLICY "Workers can view requests in their area"
    ON public.service_requests FOR SELECT
    USING (
        auth.uid() IN (
            SELECT worker_id FROM public.service_requests
            WHERE status IN ('pending', 'accepted')
        )
    );

CREATE POLICY "Workers can update assigned requests"
    ON public.service_requests FOR UPDATE
    USING (auth.uid() = worker_id);

-- Add comments for documentation
COMMENT ON TABLE public.service_requests IS 'Stores service requests from customers to workers';
COMMENT ON COLUMN public.service_requests.status IS 'Request status: pending, accepted, worker_on_the_way, arrived, in_progress, completed, cancelled';
COMMENT ON COLUMN public.service_requests.type IS 'Request type: immediate or scheduled';
```

## 2. Create Worker Locations Table

```sql
-- Create worker_locations table for real-time tracking
CREATE TABLE IF NOT EXISTS public.worker_locations (
    worker_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    is_online BOOLEAN DEFAULT true,
    last_active TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create index
CREATE INDEX IF NOT EXISTS idx_worker_locations_is_online ON public.worker_locations(is_online);

-- Enable Row Level Security
ALTER TABLE public.worker_locations ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Anyone can view worker locations"
    ON public.worker_locations FOR SELECT
    USING (true);

CREATE POLICY "Workers can update their own location"
    ON public.worker_locations FOR UPSERT
    WITH CHECK (auth.uid() = worker_id);

CREATE POLICY "Workers can insert their location"
    ON public.worker_locations FOR INSERT
    WITH CHECK (auth.uid() = worker_id);

-- Add comments
COMMENT ON TABLE public.worker_locations IS 'Real-time worker locations for tracking';
```

## 3. Create get_nearby_workers RPC Function

Returns **all online, approved workers** within `radius_km`. No category filter — the customer map shows every online worker in range.

```sql
-- Drop old 4-argument version if it exists (category_id parameter)
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

COMMENT ON FUNCTION public.get_nearby_workers IS
    'All online approved workers within radius_km of the customer (no category filter)';
```

## 4. Add per_hour_rate and completed_jobs to worker_locations

If these columns don't exist in your worker_locations or profiles table, add them:

```sql
-- Add per_hour_rate to profiles if it doesn't exist
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS per_hour_rate DOUBLE PRECISION;

-- Add completed_jobs to profiles if it doesn't exist
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS completed_jobs INTEGER DEFAULT 0;

-- Add category_id to worker_locations if it doesn't exist
ALTER TABLE public.worker_locations
    ADD COLUMN IF NOT EXISTS category_id TEXT REFERENCES public.servicesCategories(id);

-- Add category_name computed column or just store it
ALTER TABLE public.worker_locations
    ADD COLUMN IF NOT EXISTS category_name TEXT;

-- Add per_hour_rate to worker_locations for easy access
ALTER TABLE public.worker_locations
    ADD COLUMN IF NOT EXISTS per_hour_rate DOUBLE PRECISION;

-- Add completed_jobs to worker_locations for easy access
ALTER TABLE public.worker_locations
    ADD COLUMN IF NOT EXISTS completed_jobs INTEGER DEFAULT 0;
```

## 5. Create Function to Update Worker Category Info

```sql
-- Create a trigger function to update worker location with category info
CREATE OR REPLACE FUNCTION public.update_worker_category_info()
RETURNS TRIGGER AS $$
BEGIN
    -- Update category_name based on category_id
    IF NEW.category_id IS NOT NULL THEN
        SELECT name INTO NEW.category_name
        FROM public.servicesCategories
        WHERE id = NEW.category_id;
    END IF;

    -- Update per_hour_rate and completed_jobs from profiles
    SELECT
        per_hour_rate,
        completed_jobs
    INTO NEW.per_hour_rate, NEW.completed_jobs
    FROM public.profiles
    WHERE id = NEW.worker_id;

    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS worker_location_update_trigger ON public.worker_locations;
CREATE TRIGGER worker_location_update_trigger
    BEFORE INSERT OR UPDATE ON public.worker_locations
    FOR EACH ROW
    EXECUTE FUNCTION public.update_worker_category_info();
```

## 6. Enable Real-time for Tables

```sql
-- Enable realtime for service_requests
ALTER PUBLICATION supabase_realtime ADD TABLE public.service_requests;

-- Enable realtime for worker_locations
ALTER PUBLICATION supabase_realtime ADD TABLE public.worker_locations;
```

## 7. Create Updated At Trigger

```sql
-- Create a generic updated_at trigger function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS service_requests_updated_at ON public.service_requests;
CREATE TRIGGER service_requests_updated_at
    BEFORE UPDATE ON public.service_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS worker_locations_updated_at ON public.worker_locations;
CREATE TRIGGER worker_locations_updated_at
    BEFORE UPDATE ON public.worker_locations
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();
```

## Important Notes:

1. **Run these SQL commands in order** in your Supabase SQL Editor
2. Make sure your `servicesCategories` table already exists (it should from your existing setup)
3. The RPC function uses the Haversine formula to calculate distances
4. All tables have Row Level Security (RLS) enabled for security
5. Real-time is enabled for live updates

## Testing:

After running these scripts, you can test with:

```sql
-- Test the RPC function
SELECT * FROM public.get_nearby_workers(
    user_lat := 37.7749,
    user_lng := -122.4194,
    radius_km := 10.0
);

-- Check if tables were created
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('service_requests', 'worker_locations');

-- Check RLS policies
SELECT tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE tablename IN ('service_requests', 'worker_locations');
```

Let me know if you encounter any issues!
