# Tremor Test (Flutter)

Flutter client app for **drawing-based tremor testing** developed in the context of **BCI Lab** work.

Tremor testing in this app means capturing a user’s drawing trajectory (spiral / pentagon), extracting simple signal features (e.g. stability/error metrics and frequency-domain features), and saving the result for later review. This is intended for **research / prototyping / screening workflows** and is **not a medical device**.

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

## Screenshots / demo

Add screenshots or a short GIF here (recommended):

- Home screen
- Spiral drawing screen
- Result screen

Suggested path: `docs/screenshots/` (not currently included).

## Tech stack

- **Flutter** (Dart SDK `>=3.0.0 <4.0.0`)
- **Tested with**: Flutter **3.35.5** (stable), Dart **3.9.2** (from `flutter --version`)
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

Copy `.env.example` to `.env`:

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

- **iOS CocoaPods issues**
  - From `ios/`: run `pod repo update` then `pod install`
  - If you upgraded Flutter, consider `pod deintegrate && pod install` (last resort)

- **`build_runner` conflicts when switching branches**
  - Run: `flutter pub run build_runner build --delete-conflicting-outputs`

## Tremor metrics (what we compute)

The app computes and/or stores metrics similar to:

- **Error vs reference path** (e.g. mean deviation for spiral-following)
- **Frequency-domain features** (FFT-based), such as dominant tremor frequency and related magnitudes
- **Summary stats** (e.g. mean / std), plus derived overall score and category labels shown in the UI

Exact formulas and clinical interpretation are project-dependent; treat outputs as engineering features, not diagnosis.

## Backend dependency (API contract)

This repo is **frontend-only**; you must run a compatible backend that implements the endpoints below.

### Endpoints used by the app

- **Create user**: `POST /api/users`
  - JSON body:
    - `name` (string)
    - `email` (string)
    - `loginProvider` (string)
  - Success: expects **201** and a JSON object

- **Save test result**: `POST /api/tests/csv`
  - Multipart form-data:
    - `metadata` (string): **JSON** containing at least:
      - `userId` (number)
      - `testType` (string, e.g. `spiral` / `pentagon`)
      - optional numeric fields such as `overallScore`, `frequency`, `amplitude`, `mean`, `std`, etc.
      - optional `performedAt` (ISO-8601 string)
      - optional `csvContent` (string)
    - `image` (file, optional): PNG image for pentagon tests
  - Success: expects **201** and a JSON object

- **Fetch tests**: `GET /api/tests?userId=...&testType=...`
  - Success: expects **200** and a JSON array of objects

If you have a separate backend repo, link it here once known.

## Testing

Run all tests:

```bash
flutter test
```

Current tests include:
- `test/spiral_analyzer_test.dart` (unit test for spiral analysis)
- `test/widget_test.dart` (template widget test; may need updating to match the app widget tree)

## Contributing

See `CONTRIBUTING.md`.

## License

See `LICENSE`.
