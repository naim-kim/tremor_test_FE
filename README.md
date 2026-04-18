# Tremor Test (Flutter)

Flutter client app for **tremor testing** (BCI Lab). The app guides a user through drawing-based tests (e.g. **spiral drawing** and **pentagon drawing**), calculates basic tremor metrics locally, and uploads results to a backend API.

## Features

- **Login / signup**
- **Tests**
  - **Spiral drawing test** (나선 그리기 검사)
  - **Pentagon drawing test** (오각형 그리기 검사)
- **Results**
  - View latest result per test from the home screen
  - View full history (모든 기록 보기)
- **Backend integration**
  - Create user: `POST /api/users`
  - Save test result (CSV + optional image): `POST /api/tests/csv`
  - Fetch results: `GET /api/tests?userId=...&testType=...`
- **Local persistence**: stores test results locally using Hive (`test_results` box)

## Tech stack

- **Flutter** (Dart SDK `>=3.0.0 <4.0.0`)
- **State**: Provider
- **HTTP**: `package:http`
- **Storage**: Hive / SharedPreferences
- **Config**: `flutter_dotenv` (`.env` is included as a Flutter asset)

## Project structure (high level)

- `lib/main.dart`: app bootstrap, `.env` loading, Hive initialization
- `lib/config/api_config.dart`: resolves backend base URL
- `lib/services/api_client.dart`: REST API client
- `lib/screens/`: UI screens (login, home, tests, results, my page)
- `lib/widgets/`: reusable UI widgets (drawing canvas, gauges, cards)
- `lib/utils/`: analysis utilities (spiral generator/analyzer, FFT analyzer)

## Requirements

- Flutter SDK installed (stable channel recommended)
- Android Studio / Xcode (for device simulators/emulators)

## Setup

Install dependencies:

```bash
flutter pub get
```

If you modify generated model files, regenerate code:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Configure backend (`API_BASE_URL`)

This app resolves the backend base URL in this order:

1. **`.env`**: `API_BASE_URL=...` (loaded at startup if present)
2. **`--dart-define`**: `API_BASE_URL=...`
3. **Fallback defaults**
   - Web/iOS/desktop: `http://localhost:8080`
   - Android emulator: `http://10.0.2.2:8080`

### Option A: Use a `.env` file (recommended)

Create `tremor_flutter/.env`:

```env
API_BASE_URL=http://<YOUR_BACKEND_HOST>:8080
```

Notes:

- `.env` is listed under `flutter/assets` in `pubspec.yaml`, so it’s bundled into the app.
- If `.env` is missing, the app will continue using defaults (it logs a warning, but won’t crash).

### Option B: Use `--dart-define`

```bash
flutter run --dart-define=API_BASE_URL=http://<YOUR_BACKEND_HOST>:8080
```

## Run

Run on a connected device/emulator:

```bash
flutter run
```

Common cases:

- **Android emulator hitting a backend on your computer**: use `http://10.0.2.2:8080` (or set it via `.env` / `--dart-define`).
- **Physical device**: use your machine’s LAN IP (e.g. `http://192.168.0.10:8080`) and ensure the phone can reach it.

## Build

Android APK:

```bash
flutter build apk
```

Android App Bundle:

```bash
flutter build appbundle
```

iOS (requires macOS):

```bash
flutter build ios
```

## Troubleshooting

- **API calls failing / wrong host**
  - Confirm `API_BASE_URL` is correct and includes scheme + host (e.g. `http://...`)
  - For Android emulator use `10.0.2.2`, not `localhost`
- **Hive errors after model changes**
  - Ensure adapters are registered in `main.dart`
  - Re-run build_runner if generated files changed
