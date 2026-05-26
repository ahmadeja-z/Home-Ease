# 🚨 Map Requests Screen Crash - FIXED

## What Was Wrong

Your app crashed because the **database tables and RPC functions don't exist yet** in Supabase. The errors show:

1. ❌ Missing RPC function: `get_nearby_workers`
2. ❌ Missing table: `service_requests`
3. ❌ Missing table: `worker_locations`

## ✅ What I Fixed

### 1. **Added Error Handling** - App won't crash anymore!
   - Repository now gracefully handles missing database objects
   - Returns empty lists instead of crashing
   - Shows user-friendly error messages
   - Disables request button when database isn't ready

### 2. **Created Database Setup Guide**
   - File: `supabase_setup_guide.md` (in your project root)
   - Contains all SQL scripts needed
   - Step-by-step instructions
   - Testing queries included

### 3. **Added Visual Feedback**
   - Shows warning banner when database isn't set up
   - Request button shows "Setup Required"
   - Helpful messages guide users

## 📋 Next Steps - YOU MUST DO THIS

### Step 1: Open Supabase SQL Editor
1. Go to https://supabase.com/dashboard
2. Select your project
3. Click "SQL Editor" in the left sidebar
4. Click "New Query"

### Step 2: Run the Setup Script

Copy and run the SQL from `supabase_setup_guide.md` in this order:

1. **Create Service Requests Table** (Section 1)
2. **Create Worker Locations Table** (Section 2)
3. **Create get_nearby_workers Function** (Section 3)
4. **Add Additional Columns** (Section 4)
5. **Create Update Triggers** (Section 5)
6. **Enable Realtime** (Section 6)
7. **Create Updated At Trigger** (Section 7)

### Step 3: Verify Setup

Run this test query in SQL Editor:
```sql
-- Test the RPC function
SELECT * FROM public.get_nearby_workers(
    user_lat := 37.7749,
    user_lng := -122.4194,
    radius_km := 10.0
);

-- Check tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('service_requests', 'worker_locations');
```

## 🎯 After Running SQL Scripts

Once you've run the SQL scripts:

1. **Restart your app** (hot restart: `R` in terminal)
2. The map requests screen will load without crashing
3. Nearby workers will appear (once they're in the database)
4. Request button will be enabled

## 🧪 Testing

### Test 1: Check if tables exist
```sql
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('service_requests', 'worker_locations');
```

### Test 2: Check RPC function
```sql
SELECT proname
FROM pg_proc
WHERE proname = 'get_nearby_workers';
```

### Test 3: Test realtime
```sql
SELECT * FROM pg_publication_tables
WHERE pubname = 'supabase_realtime';
```

## 📱 Current App Behavior

### Before Database Setup (NOW):
- ✅ App doesn't crash
- ✅ Shows helpful "Setup Required" message
- ✅ Request button is disabled
- ✅ Warning banner explains what to do

### After Database Setup:
- ✅ App works normally
- ✅ Shows nearby workers on map
- ✅ Can create service requests
- ✅ Real-time updates work
- ✅ Full request tracking

## 🔍 Troubleshooting

### If you still see "Setup Required" after running SQL:

1. Check Supabase logs for SQL errors
2. Verify all sections were run
3. Check that tables are in `public` schema
4. Restart your Flutter app completely

### Common Issues:

**Issue**: "RPC function not found"
- **Solution**: Make sure Section 3 was run successfully

**Issue**: "Table not found"
- **Solution**: Run Section 1 and Section 2

**Issue**: "Permission denied"
- **Solution**: Check RLS policies in Section 1 & 2

**Issue**: Realtime not working
- **Solution**: Run Section 6 (Enable Realtime)

## 📝 Quick Reference

### Files to Check:
- ✅ `supabase_setup_guide.md` - SQL scripts
- ✅ `lib/repositories/map_requests_repository.dart` - Fixed error handling
- ✅ `lib/presentation/map_requests/map_requests_screen.dart` - UI feedback

### Database Objects Created:
1. `service_requests` table
2. `worker_locations` table
3. `get_nearby_workers()` RPC function
4. RLS policies for security
5. Realtime subscriptions
6. Update triggers

## 🚀 You're All Set!

Run the SQL scripts, restart the app, and you're good to go!

---

**Need Help?**
- Check the `supabase_setup_guide.md` for detailed SQL
- Review Supabase logs for errors
- Make sure you're running scripts in the correct project
