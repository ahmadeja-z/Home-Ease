# 🗺️ Map Requests Module - Complete Architecture & Flow Guide

## 📋 Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Data Models](#data-models)
4. [Request Flow](#request-flow)
5. [Supabase Integration](#supabase-integration)
6. [Real-time Updates](#real-time-updates)
7. [Complete Data Flow Diagram](#complete-data-flow-diagram)

---

## 1. Overview

The **Map Requests Module** is a real-time, location-based service request system that allows customers to:
- 📍 View nearby workers on a map
- 👷‍♂️ Filter workers by service category
- 📝 Create service requests with descriptions
- 🔴 Track worker location in real-time
- 📊 Monitor request status through the entire lifecycle
- ⭐ Rate and complete jobs

---

## 2. Architecture

### Layer Structure
```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         MapRequestsScreen (UI Layer)                 │  │
│  │  - GoogleMap with markers                            │  │
│  │  - Category selector                                 │  │
│  │  - Worker preview cards                              │  │
│  │  - Request tracking UI                               │  │
│  └───────────────────┬──────────────────────────────────┘  │
│                      │ BlocProvider & BlocBuilder          │
│  ┌───────────────────▼──────────────────────────────────┐  │
│  │              MapRequestsBloc (BLOC)                   │  │
│  │  - Handles all business logic                        │  │
│  │  - Manages state changes                             │  │
│  │  - Coordinates between UI and Repository             │  │
│  └───────────────────┬──────────────────────────────────┘  │
│                      │ Events ↓ | States ↑                 │
└──────────────────────┼──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                   DATA LAYER                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         MapRequestsRepository                        │  │
│  │  - Fetches nearby workers                           │  │
│  │  - Creates service requests                         │  │
│  │  - Listens to real-time updates                     │  │
│  │  - Updates worker locations                         │  │
│  └───────────────────┬──────────────────────────────────┘  │
│                      │                                       │
└──────────────────────┼──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│              SUPABASE BACKEND                                │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Tables:                                             │  │
│  │  • service_requests                                 │  │
│  │  • worker_locations                                 │  │
│  │  • profiles (existing)                              │  │
│  │  • servicesCategories (existing)                    │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  RPC Functions:                                      │  │
│  │  • get_nearby_workers()                              │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Realtime Subscriptions:                             │  │
│  │  • service_requests table                            │  │
│  │  • worker_locations table                            │  │
│  └──────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

---

## 3. Data Models

### A. NearbyWorkerModel
**Purpose**: Represents a worker who can provide services

**Location**: `lib/models/nearby_worker_model.dart`

**Fields**:
```dart
class NearbyWorkerModel {
  final String id;                    // Worker's user ID
  final String name;                  // Worker's full name
  final String? profileImage;         // Profile picture URL
  final double rating;                // Average rating (0-5)
  final double distance;              // Distance from user (km)
  final LatLng location;              // Current coordinates
  final bool isOnline;                // Online status
  final String? categoryId;           // Service category ID
  final String? categoryName;         // Service category name
  final double? perHourRate;          // Hourly rate
  final int? completedJobs;           // Total jobs completed
}
```

**Usage**:
- Displayed as markers on Google Map
- Shown in preview cards when tapped
- Filtered by category
- Sorted by distance

---

### B. ServiceRequestModel
**Purpose**: Represents a service request through its entire lifecycle

**Location**: `lib/models/service_request_model.dart`

**Core Fields**:
```dart
class ServiceRequestModel {
  // Identification
  final String id;                    // Unique request ID
  final String customerId;            // Customer who created it
  final String? workerId;             // Assigned worker (optional)

  // Category & Service
  final String? categoryId;           // Service category ID
  final String? categoryName;         // Service category name

  // Status & Type
  final RequestStatus status;         // Current status (enum)
  final RequestType type;             // immediate or scheduled

  // Locations
  final LatLng? customerLocation;     // Customer's coordinates
  final LatLng? workerLocation;       // Worker's current coordinates
  final String? customerAddress;      // Human-readable address

  // Details
  final String? description;          // Job description
  final double? estimatedPrice;       // Estimated cost

  // Scheduling
  final DateTime? scheduledTime;      // For scheduled requests

  // Timestamps
  final DateTime createdAt;           // When created
  final DateTime? updatedAt;          // Last update
  final DateTime? completedAt;        // When completed

  // Cancellation
  final String? cancellationReason;   // Why cancelled

  // Worker Info (populated when assigned)
  final WorkerInfo? workerInfo;       // Worker details
}
```

**RequestStatus Enum**:
```dart
enum RequestStatus {
  pending,              // Initial state, waiting for worker
  accepted,             // Worker accepted the request
  workerOnTheWay,       // Worker is moving to customer
  arrived,              // Worker reached location
  inProgress,           // Work has started
  completed,            // Job finished
  cancelled,            // Request was cancelled
}
```

**RequestType Enum**:
```dart
enum RequestType {
  immediate,            // Need service now
  scheduled,            // Schedule for later
}
```

---

### C. WorkerInfo (Nested Model)
**Purpose**: Worker details attached to service request

**Fields**:
```dart
class WorkerInfo {
  final String id;                    // Worker's user ID
  final String name;                  // Worker's name
  final String? profileImage;         // Profile picture
  final double? rating;               // Worker's rating
  final String? phoneNumber;          // Contact number
  final LatLng? location;             // Current location
}
```

---

## 4. Request Flow

### Complete Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│                    1. INITIAL STATE                         │
│                                                             │
│  Customer opens app → Nearby workers loaded on map          │
│  • User location obtained via Geolocator                     │
│  • RPC function: get_nearby_workers() called                │
│  • Workers displayed as markers within radius                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    2. CATEGORY FILTER                       │
│                                                             │
│  Customer selects category → Workers filtered               │
│  • CategoryId passed to get_nearby_workers()                │
│  • Map updates with filtered markers                        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    3. WORKER SELECTION                      │
│                                                             │
│  Customer taps marker → Preview card appears                │
│  • Worker details shown (rating, rate, distance)            │
│  • Can view profile or request directly                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    4. REQUEST CREATION                       │
│                                                             │
│  Customer clicks "Request" → Bottom sheet opens             │
│  • Select category (if not selected)                        │
│  • Add description (optional)                               │
│  • Submit → CreateServiceRequestEvent sent                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    5. REQUEST PERSISTENCE                    │
│                                                             │
│  Bloc → Repository → Supabase                                │
│  • Insert record into service_requests table                │
│  • Status: "pending"                                        │
│  • Customer location & address saved                        │
│  • Category & description saved                             │
│  • Returns ServiceRequestModel                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    6. PENDING STATE                         │
│                                                             │
│  Request awaiting worker acceptance                          │
│  • UI shows "Searching for worker..."                       │
│  • Real-time subscription active                            │
│  • Cancel button available                                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    7. WORKER ACCEPTS                        │
│                                                             │
│  Worker accepts request (via separate worker app)            │
│  • service_requests updated: worker_id = worker.id          │
│  • status changed to "accepted"                             │
│  • Real-time update received by customer app                │
│  • UI shows worker details + "On the way"                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    8. WORKER ON THE WAY                     │
│                                                             │
│  Worker navigates to customer location                       │
│  • Worker location updates in worker_locations table         │
│  • status changed to "worker_on_the_way"                    │
│  • Customer sees worker moving on map                       │
│  • ETA shown (if implemented)                               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    9. ARRIVED STATE                         │
│                                                             │
│  Worker reaches customer location                            │
│  • status changed to "arrived"                              │
│  • Customer notified (push notification)                    │
│  • UI shows "Worker has arrived"                            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    10. IN PROGRESS                          │
│                                                             │
│  Worker starts job                                           │
│  • status changed to "in_progress"                          │
│  • Customer sees "Work in progress"                         │
│  • Timer/Tracking begins                                    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    11. COMPLETION                           │
│                                                             │
│  Worker finishes job → Customer confirms                     │
│  • Customer clicks "Complete" button                        │
│  • Review dialog appears (optional rating)                  │
│  • CompleteJobEvent sent                                    │
│  • status changed to "completed"                            │
│  • completed_at timestamp set                               │
│  • Rating & review saved                                    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    12. POST-JOB                             │
│                                                             │
│  Request completed successfully                               │
│  • UI shows "Job completed" message                         │
│  • Worker rating updated                                    │
│  • Request archived                                         │
│  • Ready for new request                                    │
└─────────────────────────────────────────────────────────────┘

                   (Any state can be cancelled)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    CANCELLATION FLOW                         │
│                                                             │
│  Customer or Worker cancels                                  │
│  • CancelJobEvent sent                                      │
│  • status changed to "cancelled"                            │
│  • cancellation_reason saved                                │
│  • UI shows "Request cancelled"                             │
│  • Worker notified (if assigned)                            │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Supabase Integration

### A. Database Tables

#### 1. service_requests
**Purpose**: Stores all service requests with complete lifecycle data

**Schema**:
```sql
CREATE TABLE service_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES auth.users(id),
    worker_id UUID REFERENCES auth.users(id),

    -- Category & Service Info
    category_id TEXT NOT NULL,
    category_name TEXT,

    -- Locations
    customer_latitude DOUBLE PRECISION NOT NULL,
    customer_longitude DOUBLE PRECISION NOT NULL,
    customer_address TEXT NOT NULL,
    worker_latitude DOUBLE PRECISION,
    worker_longitude DOUBLE PRECISION,

    -- Worker Info (Denormalized for quick access)
    worker_name TEXT,
    worker_profile_picture TEXT,
    worker_rating DOUBLE PRECISION,
    worker_phone TEXT,

    -- Details
    description TEXT,
    status TEXT NOT NULL DEFAULT 'pending',
    type TEXT NOT NULL DEFAULT 'immediate',
    estimated_price DOUBLE PRECISION,

    -- Scheduling
    scheduled_time TIMESTAMPTZ,

    -- Reviews
    review TEXT,
    rating DOUBLE PRECISION,

    -- Cancellation
    cancellation_reason TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,

    -- Constraints
    CHECK (status IN ('pending', 'accepted', 'worker_on_the_way',
                      'arrived', 'in_progress', 'completed', 'cancelled')),
    CHECK (type IN ('immediate', 'scheduled'))
);
```

**Indexes**:
```sql
CREATE INDEX idx_service_requests_customer_id ON service_requests(customer_id);
CREATE INDEX idx_service_requests_worker_id ON service_requests(worker_id);
CREATE INDEX idx_service_requests_status ON service_requests(status);
CREATE INDEX idx_service_requests_created_at ON service_requests(created_at DESC);
```

**RLS Policies**:
```sql
-- Customers can view their own requests
CREATE POLICY "Customers view own requests"
    ON service_requests FOR SELECT
    USING (auth.uid() = customer_id);

-- Customers can create requests
CREATE POLICY "Customers create requests"
    ON service_requests FOR INSERT
    WITH CHECK (auth.uid() = customer_id);

-- Customers can update their requests
CREATE POLICY "Customers update own requests"
    ON service_requests FOR UPDATE
    USING (auth.uid() = customer_id);

-- Workers can view assigned requests
CREATE POLICY "Workers view assigned requests"
    ON service_requests FOR SELECT
    USING (auth.uid() = worker_id);

-- Workers can update assigned requests
CREATE POLICY "Workers update assigned requests"
    ON service_requests FOR UPDATE
    USING (auth.uid() = worker_id);
```

---

#### 2. worker_locations
**Purpose**: Real-time worker location tracking

**Schema**:
```sql
CREATE TABLE worker_locations (
    worker_id UUID REFERENCES auth.users(id) PRIMARY KEY,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    is_online BOOLEAN DEFAULT true,
    category_id TEXT REFERENCES servicesCategories(id),
    category_name TEXT,
    per_hour_rate DOUBLE PRECISION,
    completed_jobs INTEGER DEFAULT 0,
    last_active TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Realtime**:
```sql
ALTER PUBLICATION supabase_realtime
    ADD TABLE worker_locations;
```

---

### B. RPC Functions

#### get_nearby_workers()
**Purpose**: Find workers within a radius, filtered by category

**Implementation**:
```sql
CREATE FUNCTION get_nearby_workers(
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
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.name,
        p.profile_picture,
        COALESCE(p.rating, 0.0) as rating,
        -- Haversine formula for distance calculation
        (6371 * acos(
            cos(radians(user_lat)) *
            cos(radians(wl.latitude)) *
            cos(radians(wl.longitude) - radians(user_lng)) +
            sin(radians(user_lat)) *
            sin(radians(wl.latitude))
        )) as distance,
        wl.latitude,
        wl.longitude,
        wl.is_online,
        wl.category_id,
        wl.category_name,
        wl.per_hour_rate,
        wl.completed_jobs
    FROM worker_locations wl
    JOIN profiles p ON p.id = wl.worker_id
    LEFT JOIN servicesCategories sc ON sc.id = wl.category_id
    WHERE
        p.role = 'worker'
        AND p.status = 'approved'
        AND p.is_active = true
        AND wl.is_online = true
        AND (category_id IS NULL OR wl.category_id = category_id)
        AND (
            6371 * acos(
                cos(radians(user_lat)) *
                cos(radians(wl.latitude)) *
                cos(radians(wl.longitude) - radians(user_lng)) +
                sin(radians(user_lat)) *
                sin(radians(wl.latitude))
            ) <= radius_km
        )
    ORDER BY distance ASC;
END;
$$;
```

**How It Works**:
1. Takes user's latitude & longitude
2. Uses Haversine formula to calculate distance
3. Filters by radius (default 10km)
4. Filters by category (optional)
5. Returns only online, approved workers
6. Sorted by distance (nearest first)

---

## 6. Real-time Updates

### How Real-time Works

```
┌─────────────────────────────────────────────────────────────┐
│                    SUPABASE REALTIME                        │
│                                                             │
│  When service_requests row is updated:                      │
│  1. Database triggers ROW UPDATED event                    │
│  2. Supabase broadcasts to all subscribers                │
│  3. Customer app receives update via WebSocket             │
│  4. Bloc processes update & emits new state                │
│  5. UI rebuilds with latest data                            │
└─────────────────────────────────────────────────────────────┘
```

### Subscription Flow

**In Repository**:
```dart
Stream<ServiceRequestModel> listenActiveRequest(String customerId) {
  return supabase
      .from('service_requests')
      .stream(primaryKey: ['id'])
      .eq('customer_id', customerId)
      .map((event) => ServiceRequestModel.fromJson(event));
}
```

**In Bloc**:
```dart
_activeRequestSubscription = repository
    .listenActiveRequest(userId)
    .listen((request) {
  emit(state.copyWith(
    activeRequest: request,
    status: _getStatusFromRequest(request),
  ));
});
```

**Update Triggers**:
- Worker accepts → status: 'pending' → 'accepted'
- Worker on way → status: 'accepted' → 'worker_on_the_way'
- Worker arrives → status: 'worker_on_the_way' → 'arrived'
- Worker starts → status: 'arrived' → 'in_progress'
- Job done → status: 'in_progress' → 'completed'

---

## 7. Complete Data Flow Diagram

### Creating a Service Request

```
┌──────────────────┐
│   CUSTOMER UI    │
│                  │
│  1. Taps marker  │
│  2. Selects cat  │
│  3. Adds desc    │
│  4. Submits      │
└────────┬─────────┘
         │ CreateServiceRequestEvent
         ↓
┌──────────────────────────────────────────────┐
│              MAP REQUESTS BLOC              │
│                                              │
│  _onCreateServiceRequest()                   │
│  1. Emit status: requestSending             │
│  2. Get user ID from auth                   │
│  3. Call repository.createServiceRequest()  │
└────────┬─────────────────────────────────────┘
         │
         ↓
┌──────────────────────────────────────────────┐
│          MAP REQUESTS REPOSITORY             │
│                                              │
│  createServiceRequest()                      │
│  1. Validate user authentication             │
│  2. Prepare request data                     │
│  3. Supabase INSERT operation                │
└────────┬─────────────────────────────────────┘
         │
         ↓
┌──────────────────────────────────────────────┐
│              SUPABASE                        │
│                                              │
│  INSERT INTO service_requests (              │
│    customer_id,                              │
│    category_id,                              │
│    customer_latitude,                        │
│    customer_longitude,                       │
│    customer_address,                         │
│    description,                              │
│    status = 'pending',                       │
│    type = 'immediate'                        │
│  )                                           │
│                                              │
│  RETURNING *                                 │
└────────┬─────────────────────────────────────┘
         │
         │ ServiceRequestModel
         ↓
┌──────────────────────────────────────────────┐
│              MAP REQUESTS BLOC              │
│                                              │
│  1. Receive response                         │
│  2. Emit status: requestCreated             │
│  3. Store in state.activeRequest            │
│  4. Trigger listenActiveRequest()            │
└────────┬─────────────────────────────────────┘
         │
         ↓
┌──────────────────────────────────────────────┐
│          MAP REQUESTS REPOSITORY             │
│                                              │
│  listenActiveRequest()                       │
│  1. Subscribe to service_requests stream     │
│  2. Filter by customer_id                    │
│  3. Filter by active statuses                │
└────────┬─────────────────────────────────────┘
         │
         │ Real-time stream
         ↓
┌──────────────────────────────────────────────┐
│              SUPABASE                        │
│                                              │
│  Real-time subscription active               │
│  • Listening for UPDATE events               │
│  • Broadcasts changes immediately            │
└──────────────────────────────────────────────┘
         │
         │ Status updates flow back
         ↓
┌──────────────────────────────────────────────┐
│              MAP REQUESTS BLOC              │
│                                              │
│  Stream listener receives updates:           │
│  • Worker accepts → status: 'accepted'       │
│  • Worker on way → status: 'worker_on_the_way'│
│  • Worker arrives → status: 'arrived'        │
│  • Worker starts → status: 'in_progress'     │
│                                              │
│  Each update:                                │
│  1. Update state.activeRequest               │
│  2. Emit new state                           │
│  3. Trigger UI rebuild                       │
└────────┬─────────────────────────────────────┘
         │
         ↓
┌──────────────────────────────────────────────┐
│               CUSTOMER UI                   │
│                                              │
│  BlocBuilder rebuilds:                       │
│  • Shows current status                      │
│  • Updates progress indicators               │
│  • Displays worker info                      │
│  • Shows action buttons (cancel/complete)    │
└──────────────────────────────────────────────┘
```

---

## 8. Summary: How Requests Are Sent to Supabase

### Step-by-Step Process

**1. User Action → Event**
```dart
// UI: User clicks "Request" button
context.read<MapRequestsBloc>().add(
  CreateServiceRequestEvent(
    categoryId: category.id,
    categoryName: category.name,
    customerLocation: userLocation,
    customerAddress: 'Current Location',
    description: 'Need plumbing repair',
  ),
);
```

**2. Bloc Event Handler**
```dart
Future<void> _onCreateServiceRequest(
  CreateServiceRequestEvent event,
  Emitter<MapRequestsState> emit,
) async {
  // Update UI state
  emit(state.copyWith(status: MapRequestStatus.requestSending));

  try {
    // Call repository
    final request = await repository.createServiceRequest(
      categoryId: event.categoryId,
      categoryName: event.categoryName,
      customerLocation: event.customerLocation,
      customerAddress: event.customerAddress,
      description: event.description,
      requestType: event.requestType.name,
    );

    // Update state with created request
    emit(state.copyWith(
      status: MapRequestStatus.requestCreated,
      activeRequest: request,
    ));

    // Start listening for updates
    add(ListenActiveRequestEvent());
  } catch (e) {
    // Handle errors
    emit(state.copyWith(
      status: MapRequestStatus.error,
      errorMessage: e.toString(),
    ));
  }
}
```

**3. Repository → Supabase**
```dart
Future<ServiceRequestModel> createServiceRequest({
  required String categoryId,
  required String categoryName,
  required LatLng customerLocation,
  required String customerAddress,
  String? description,
  required String requestType,
}) async {
  // Get authenticated user
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) {
    throw Exception('User not authenticated');
  }

  // Prepare data
  final requestData = {
    'customer_id': userId,
    'category_id': categoryId,
    'category_name': categoryName,
    'customer_latitude': customerLocation.latitude,
    'customer_longitude': customerLocation.longitude,
    'customer_address': customerAddress,
    'description': description,
    'status': 'pending',
    'type': requestType,
  };

  // Insert into Supabase
  final response = await supabase
      .from('service_requests')
      .insert(requestData)
      .select()
      .single();

  // Return model
  return ServiceRequestModel.fromJson(response);
}
```

**4. Supabase SQL**
```sql
-- What actually happens in Supabase
INSERT INTO service_requests (
    customer_id,
    category_id,
    category_name,
    customer_latitude,
    customer_longitude,
    customer_address,
    description,
    status,
    type
) VALUES (
    'uuid-of-customer',
    'plumbing',
    'Plumbing Services',
    37.7749,
    -122.4194,
    '123 Main St, City',
    'Need plumbing repair',
    'pending',
    'immediate'
)
RETURNING *;
```

**5. Real-time Listening Begins**
```dart
// After creation, listen for updates
_activeRequestSubscription = repository
    .listenActiveRequest(userId)
    .listen((request) {
  // This fires whenever the request is updated in Supabase
  emit(state.copyWith(
    activeRequest: request,
    status: _getStatusFromRequest(request),
  ));
});
```

---

## 9. Key Models in Supabase

### Table: service_requests
**Required columns for request creation**:
- `customer_id` (UUID) - From auth
- `category_id` (TEXT) - From UI selection
- `category_name` (TEXT) - From UI selection
- `customer_latitude` (DOUBLE) - From GPS
- `customer_longitude` (DOUBLE) - From GPS
- `customer_address` (TEXT) - From location services
- `description` (TEXT) - Optional, from user input
- `status` (TEXT) - Auto-set to 'pending'
- `type` (TEXT) - Auto-set to 'immediate'

**Populated by Supabase**:
- `id` - Auto-generated UUID
- `created_at` - Auto-set timestamp
- `updated_at` - Auto-update trigger

**Populated when worker accepts**:
- `worker_id` - Worker's UUID
- `worker_name` - Worker's name
- `worker_profile_picture` - Worker's photo
- `worker_rating` - Worker's rating
- `worker_phone` - Worker's phone

---

### Table: worker_locations
**Required for nearby workers**:
- `worker_id` (UUID) - Worker's user ID
- `latitude` (DOUBLE) - Current location
- `longitude` (DOUBLE) - Current location
- `is_online` (BOOLEAN) - Online status

**Optional**:
- `category_id` (TEXT) - Primary service category
- `category_name` (TEXT) - Category name
- `per_hour_rate` (DOUBLE) - Hourly rate
- `completed_jobs` (INTEGER) - Job count

---

## 10. Complete Request Example

### Initial Request (Customer → Supabase)
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "customer_id": "customer-uuid-123",
  "worker_id": null,
  "category_id": "plumbing",
  "category_name": "Plumbing Services",
  "customer_latitude": 37.7749,
  "customer_longitude": -122.4194,
  "customer_address": "123 Main St, San Francisco, CA",
  "worker_latitude": null,
  "worker_longitude": null,
  "worker_name": null,
  "worker_profile_picture": null,
  "worker_rating": null,
  "worker_phone": null,
  "description": "Kitchen sink leaking, needs repair ASAP",
  "status": "pending",
  "type": "immediate",
  "estimated_price": null,
  "scheduled_time": null,
  "review": null,
  "rating": null,
  "cancellation_reason": null,
  "created_at": "2026-05-10T10:30:00Z",
  "updated_at": "2026-05-10T10:30:00Z",
  "completed_at": null
}
```

### After Worker Accepts
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "customer_id": "customer-uuid-123",
  "worker_id": "worker-uuid-456",
  "category_id": "plumbing",
  "category_name": "Plumbing Services",
  "customer_latitude": 37.7749,
  "customer_longitude": -122.4194,
  "customer_address": "123 Main St, San Francisco, CA",
  "worker_latitude": 37.7750,
  "worker_longitude": -122.4195,
  "worker_name": "John Smith",
  "worker_profile_picture": "https://...",
  "worker_rating": 4.8,
  "worker_phone": "+1234567890",
  "description": "Kitchen sink leaking, needs repair ASAP",
  "status": "accepted",
  "type": "immediate",
  "estimated_price": null,
  "scheduled_time": null,
  "review": null,
  "rating": null,
  "cancellation_reason": null,
  "created_at": "2026-05-10T10:30:00Z",
  "updated_at": "2026-05-10T10:32:00Z",
  "completed_at": null
}
```

---

## 🎯 Summary

### What Models Should Be Present in Supabase:

1. **service_requests table** - Main request storage
2. **worker_locations table** - Real-time worker tracking
3. **get_nearby_workers()** - RPC function to find workers

### Data Flow Summary:

```
User Input → Bloc Event → Repository → Supabase INSERT
                ↓
            State Update
                ↓
            Real-time Subscription
                ↓
        Listen for Updates (WebSocket)
                ↓
        Supabase broadcasts changes
                ↓
        Bloc receives update → State update → UI rebuild
```

### Key Points:

✅ All requests stored in `service_requests` table
✅ Real-time updates via Supabase streams
✅ Worker locations tracked separately
✅ RPC function for finding nearby workers
✅ Complete audit trail with timestamps
✅ RLS policies for security
✅ Support for cancellation & reviews
✅ Flexible status workflow

This architecture ensures a scalable, real-time, and production-ready service request system! 🚀
