# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

My Note App is a Flutter-based note-taking application with rich text editing, password protection, light/dark theme support, and cloud sync via Appwrite. The project uses GetX for state management and MVC pattern for architecture.

## Build & Run Commands

### Development
```bash
# Get dependencies
flutter pub get

# Run app in debug mode
flutter run

# Run on specific device
flutter run -d <device_id>
```

### Build
```bash
# iOS
flutter build ios

# Android
flutter build apk

# Web (if configured)
flutter build web
```

### Linting & Analysis
```bash
# Run Flutter analyzer
flutter analyze

# Format code
dart format lib/

# Fix auto-fixable linting issues
dart fix --apply lib/
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage (if lcov installed)
flutter test --coverage
```

### Clean Build
```bash
flutter clean
flutter pub get
flutter run
```

## Architecture Overview

The project follows an MVC-inspired pattern with GetX dependency injection:

### Core Structure

**State Management (GetX)**
- Controllers handle business logic and state: `lib/controller/` contains `NoteController`, `AuthController`, and `BackgroundController`
- `NoteController` manages notes, theme, and password functionality
- `AuthController` handles Google Sign-In authentication
- Dependency injection via `helper/dependency.dart` - all controllers are lazily initialized at app startup

**Models**
- `Note` model in `lib/model/note_model.dart`: Core data structure with title, content, color, timestamps, favorite status
- `UserModel` for authentication data
- Models include JSON serialization (`toJson()`, `fromJson()`) and update mappings

**Database Layer**
- SQLite via `sqflite` managed in `lib/database_helper/database_helper.dart`
- Singleton pattern for database access
- Single table schema: `notes` with fields (note_id, title, content, dateTimeEdited, dateTimeCreated, isFavorite, color)
- Order by dateTimeCreated DESC for note listing

**Cloud Integration**
- Appwrite backend configured in `lib/appwrite/app_write_config.dart` (endpoint: fra.cloud.appwrite.io, projectId: 68c477bd0025144ebd1c)
- `AppwriteService` singleton for database operations
- `AppWriteRepository` wraps Appwrite API calls
- Supports sync of notes to cloud with author email tracking

**Routing**
- GetX-based routing in `lib/routing/app_routes.dart`
- Key routes: password screen (`/password`), home (`/home`), add/edit/detail note screens
- Note data passed via base64-encoded JSON in URL parameters for edit/detail routes

**Screens**
- `HomePage`: Main note list with search, add, edit, delete, favorite, and color customization
- `AddNewNotePage` / `EditNotePage`: Rich text editing via flutter_quill
- `PassScreen` / `ForgetPassScreen`: Password protection with security questions
- `SettingScreen`: Theme toggle and app settings
- `SearchScreen`: Note search functionality
- Note detail view with read-only quill editor

**Widgets**
- Reusable components: `NoteCard`, `DrawerWidget`, `ColorPickerSheet`, `TextEditWidget`, alert dialogs
- Rich text editing handled by `flutter_quill` with helper in `lib/helper/quill_helper.dart`

### Key Dependencies
- **GetX** (4.3.8): State management and routing
- **flutter_quill** (11.4.2): Rich text editing
- **sqflite** (2.0.0+4): Local SQLite database
- **shared_preferences** (2.2.3): Persistent app settings (password, theme, auth tokens)
- **google_sign_in** (6.2.1): Google authentication
- **appwrite** (19.0.0): Cloud backend
- **image_picker** (1.1.2): Background image selection
- **speech_to_text** (7.0.0): Voice input (integrated but not fully utilized)
- **flutter_quill** localizations via FlutterQuillLocalizations delegate

### Theme System
- Dual theme support: `lib/theme/light_theme.dart` and `lib/theme/dark_theme.dart`
- Google Fonts (Inter) integration for typography
- Material 3 design system with custom color schemes
- Theme state stored in SharedPreferences (`AppConstants.theme` key)
- Toggle via `NoteController.toggleTheme()`

### Utilities & Constants
- **app_constants.dart**: SharedPreferences keys for auth, password, theme, background images
- **colors.dart**: Basic color definitions (mostly unused, theme system preferred)
- **font_size.dart**: Standardized font sizes (small, medium, extraMedium, mediumLarge, large)
- **padding_size.dart**: Spacing constants (extraSmall, small, medium, large)
- **radius_size.dart**: Border radius constants
- **style.dart**: Text style presets (normal, medium, large, extraLarge, bold)
- **color_extension.dart**: String hex-to-Color conversion utilities

### SharedPreferences Schema
```
account: user email (Google Sign-In)
account_name: user display name
account_image: user avatar URL
password: app lock password
password-activation: boolean for password protection
suggestions: list of security question answers for password recovery
theme: boolean for dark mode
opacity: background image opacity
backgroundImage: selected background image path
```

## Important Implementation Details

### Password & Security
- Password stored as plain text in SharedPreferences (consider enhancement)
- Password activation separate from password existence
- Security questions stored for "forget password" recovery flow
- App checks password on startup via `checkPasswordAllow()`

### Note Data Flow
- New notes auto-increment ID via `DatabaseHelper.getNextId()`
- All date operations use `DateFormat("dd-MM-yyyy hh:mm a")` for local storage, UTC ISO8601 for cloud
- Note color stored as hex string (default: '#FFA0A4A8')
- Favorite status tracked as integer (0/1) in database
- Note passing between screens uses base64-encoded JSON in URL parameters

### Rich Text Content
- Content stored as JSON-serialized Quill Document (via flutter_quill)
- `QuillHelper` provides conversion: `convertStringDocumentToString()` for plain text extraction
- `deriveTitleAndBody()` extracts title from first non-empty line and body from remainder

### Theme & UI Customization
- Dynamic note card background colors (hex string to Color conversion via extension)
- Background image opacity stored separately from image path
- Light theme: neutral grays/blacks on light surface
- Dark theme: light text on dark surface (0xFF0E0E0E base)

## File Locations Reference

**Controllers**: `lib/controller/`
**Models**: `lib/model/`
**Screens**: `lib/screens/` (organized by feature: pass_screen/, note_screens/, setting_screen/)
**Widgets**: `lib/widgets/`
**Database**: `lib/database_helper/`
**Routing**: `lib/routing/`
**Theme**: `lib/theme/`
**Utils**: `lib/utils/`
**Helpers**: `lib/helper/`
**Cloud**: `lib/appwrite/`
**Assets**: `assets/` (contains no_note.jpg placeholder)

## Development Notes

- App initializes with `di.init()` in main before runApp
- NoteController is a GetxService (singleton) - accessed via `Get.find<NoteController>()`
- Print statements throughout codebase for debugging (consider replacing with logger)
- flutter_quill requires FlutterQuillLocalizations delegate for multi-language support
- Appwrite TablesDB API used for note sync (newer API vs traditional Databases)
- Google Sign-In requires platform-specific setup (iOS: GoogleService-Info.plist, Android: google-services.json)
