# Warehouse Picker - Mobile App

Flutter mobile application for warehouse pickers to manage batch picking operations.

## Building APK with Codemagic

### Setup Instructions

1. Go to [Codemagic](https://codemagic.io) and log in
2. Click "Add application" and connect your repository
3. Select this repository
4. Codemagic will automatically detect `codemagic.yaml` in the project root
5. Start a new build - select "android-workflow"
6. Once the build completes, download the APK from the artifacts

### Configuration

After installing the APK on your device:

1. Open the app
2. Tap the settings icon (gear) in the top right
3. Enter your API Base URL (your deployed Replit app URL, e.g., `https://your-app-name.replit.app`)
4. Tap "Save"

The app will now connect to your warehouse backend.

## Features

- **Marketplace Tabs**: Switch between WB, Ozon, and Yandex Market batches
- **Batch List**: View all open batches for each marketplace
- **Pick Lines**: See items to pick grouped by product type
- **Confirmation**: Confirm picked items and close batches

## Project Structure

```
mobile/
├── lib/
│   └── main.dart          # Main application code
├── android/               # Android-specific configuration
├── pubspec.yaml           # Flutter dependencies
├── codemagic.yaml         # Codemagic CI/CD configuration
└── analysis_options.yaml  # Dart linting rules
```

## Local Development

If you have Flutter installed locally:

```bash
cd mobile
flutter pub get
flutter run
```

## API Endpoints Used

- `GET /api/picker/batches?marketplace={WB|Ozon|YandexMarket}` - List open batches
- `GET /api/picker/batches/:id/lines` - Get pick lines for a batch
- `POST /api/picker/batches/:id/lines/:lineId/confirm` - Confirm a pick line
- `POST /api/picker/batches/:id/close` - Close a batch
