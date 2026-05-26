# HomeEase

HomeEase is a Flutter service-booking application for connecting customers with nearby home-service workers. The app supports authentication, service/category browsing, map-based worker discovery, service request tracking, multilingual UI, light/dark themes, and push notifications.

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Running the App](#running-the-app)
- [Backend and Database](#backend-and-database)
- [App Architecture](#app-architecture)
- [Key Workflows](#key-workflows)
- [Localization](#localization)
- [Testing and Quality Checks](#testing-and-quality-checks)
- [Troubleshooting](#troubleshooting)
- [Related Documentation](#related-documentation)

## Features

- Customer sign up, login, logout, password reset, and password change.
- User profile loading, local persistence, profile editing, and profile image support.
- Home dashboard with banners, service categories, and services loaded from Supabase.
- Category-based service browsing.
- Map request screen with current-location lookup, nearby worker markers, and request creation.
- Real-time service request updates using Supabase streams.
- Request lifecycle support: pending, accepted, worker on the way, arrived, in progress, completed, and cancelled.
- Firebase Cloud Messaging and local notifications.
- Light and dark themes with saved theme preference.
- Responsive breakpoints for mobile, tablet, desktop, and 4K layouts.
- Multilingual support for English, Arabic, Spanish, French, French Canada, Korean, and Portuguese Brazil.

## Tech Stack

- **Framework:** Flutter
- **Language:** Dart
- **State management:** BLoC and Flutter BLoC
- **Backend:** Supabase Auth, Database, Storage, Realtime, and RPC
- **Notifications:** Firebase Cloud Messaging and Flutter Local Notifications
- **Maps and location:** Google Maps Flutter, Geolocator, Flutter Polyline Points
- **Networking:** Dio and HTTP
- **Local storage:** Shared Preferences
- **Localization:** Easy Localization
- **Responsive UI:** Responsive Framework

## Project Structure

```text
homeease/
|-- android/                  # Android platform project
|-- ios/                      # iOS platform project
|-- assets/
|   |-- fonts/                # Poppins and Montserrat fonts
|   |-- images/               # Logos and language flag assets
|   `-- translations/         # Easy Localization JSON files
|-- lib/
|   |-- core/
|   |   |-- assets/           # App asset constants
|   |   |-- responsive/       # Responsive helpers
|   |   |-- services/         # API, notification, maps, storage, permission services
|   |   |-- theme/            # App themes and theme BLoC
|   |   `-- utils/            # Validators, constants, labels, helpers
|   |-- models/               # Data models
|   |-- presentation/         # Screens, widgets, and feature BLoCs
|   |-- repositories/         # Supabase/API data access layer
|   |-- routes/               # Route names and route generation
|   |-- widgets/              # Shared UI widgets
|   |-- firebase_options.dart # Firebase platform configuration
|   `-- main.dart             # App bootstrap
|-- test/                     # Flutter tests
|-- web/                      # Web platform project
|-- MAP_REQUESTS_ARCHITECTURE.md
|-- CRASH_FIX_INSTRUCTIONS.md
|-- supabase_setup_guide.md
`-- pubspec.yaml
```

## Prerequisites

Install the following before running the project:

- Flutter SDK compatible with Dart `^3.10.4`
- Android Studio or Xcode for mobile builds
- A configured Firebase project
- A configured Supabase project
- Google Maps API key for map rendering

Check your local Flutter environment:

```bash
flutter doctor
```

## Environment Setup

Create a `.env` file in the project root with the following keys:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

The app loads this file from `lib/main.dart` using `flutter_dotenv`, and `.env` is declared as an asset in `pubspec.yaml`.

Firebase config files are expected at:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

Google Maps configuration is currently defined in the Android manifest. For production, keep API keys restricted in Google Cloud Console and avoid committing unrestricted keys.

## Running the App

Install packages:

```bash
flutter pub get
```

Run on the connected device or emulator:

```bash
flutter run
```

Run a specific target:

```bash
flutter run -d chrome
flutter run -d android
flutter run -d ios
```

Build release artifacts:

```bash
flutter build apk --release
flutter build ios --release
flutter build web --release
```

## Backend and Database

HomeEase uses Supabase as the primary backend. The app expects these main tables and functions:

- `profiles` for user profile data, roles, status, verification, address, and FCM token.
- `servicesCategories` for service category records.
- `services` for available home services.
- `banners` for dashboard banner content.
- `service_requests` for customer requests and job lifecycle state.
- `worker_locations` for live worker location and availability.
- `get_nearby_workers` RPC for radius-based worker search.

The map request database setup is documented in `supabase_setup_guide.md`. Run the SQL from that guide in the Supabase SQL editor before using the map request flow.

## App Architecture

The project follows a feature-oriented Flutter structure:

- **Screens and widgets** live in `lib/presentation`.
- **BLoCs** manage UI state and user actions for auth, home, language, map requests, navbar, profile, selected category, and theme.
- **Repositories** isolate data access and communicate with Supabase or APIs.
- **Models** convert Supabase/API payloads into typed Dart objects.
- **Core services** handle cross-cutting concerns such as notifications, permissions, local storage, maps, geocoding, API calls, and system UI.
- **Routes** are centralized through `AppRoutes.generateRoute`.

Application startup happens in `lib/main.dart`:

1. Loads `.env`.
2. Initializes Flutter bindings.
3. Initializes Firebase.
4. Registers the Firebase background message handler.
5. Initializes Supabase.
6. Initializes localization.
7. Initializes notifications.
8. Loads cached user data.
9. Registers repositories and BLoCs.
10. Starts the app at `SplashScreen`.

## Key Workflows

### Authentication

`AuthRepository` uses Supabase Auth for login, sign up, reset password, change password, and logout. User profile data is read from the `profiles` table and saved locally through `UserRepository`.

### Home Dashboard

`HomeBloc` loads dashboard banners, service categories, and services through `HomeRepository`. Data comes from Supabase tables and supports pagination and search parameters.

### Map Requests

`MapRequestsBloc` coordinates location access, nearby worker loading, worker marker generation, request creation, active request listening, and job status changes. `MapRequestsRepository` performs Supabase reads, writes, streams, and RPC calls.

### Notifications

`NotificationService` initializes Firebase Messaging, local notifications, foreground notification display, token refresh handling, and token sync to the current user profile.

### Theming

`ThemeBloc` loads and updates the selected theme mode through `ThemeRepository`. `MaterialApp` applies `AppTheme.lightTheme` or `AppTheme.darkTheme`.

## Localization

Translation files live in `assets/translations`:

- `en.json`
- `ar.json`
- `es.json`
- `fr.json`
- `fr-CA.json`
- `ko.json`
- `pt-BR.json`

Supported locales are registered in `lib/main.dart`. Add a new language by creating a JSON file, adding it to the supported locale list, and ensuring the asset path remains included in `pubspec.yaml`.

## Testing and Quality Checks

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Format Dart code:

```bash
dart format lib test
```

## Troubleshooting

### `.env` values are missing

Make sure `.env` exists at the project root and contains `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

### Map requests show no workers

Confirm that the Supabase SQL from `supabase_setup_guide.md` has been applied, realtime is enabled for the required tables, workers have location rows, and the `get_nearby_workers` RPC exists.

### Notifications do not arrive

Check Firebase configuration files, platform notification permissions, APNs setup for iOS, and whether the user profile has an updated `deviceFcmToken`.

### Location does not work

Confirm device location services are enabled and runtime permissions are granted. Android permissions are in `android/app/src/main/AndroidManifest.xml`; iOS usage descriptions are in `ios/Runner/Info.plist`.

### Firebase initialization fails

Regenerate Firebase options with FlutterFire CLI if Firebase project settings changed:

```bash
flutterfire configure
```

## Related Documentation

- `supabase_setup_guide.md` - SQL setup for map requests, worker locations, realtime, triggers, and RPC.
- `MAP_REQUESTS_ARCHITECTURE.md` - Detailed map request architecture and request lifecycle.
- `CRASH_FIX_INSTRUCTIONS.md` - Notes about the map request crash fix and setup validation.
