# My Note App 📝

A feature-rich, beautiful, and secure note-taking application built with Flutter. My Note App offers a seamless experience for capturing thoughts, organizing ideas, and keeping your information safe.

## 🚀 Features

- **Rich Text Editing:** Powerful editor powered by `flutter_quill` with support for formatting, lists, headers, and more.
- **Media Support:** Seamlessly attach, drag-and-drop, and crop images within your notes.
- **Security:** Protect your sensitive notes with App Lock (PIN code & Biometrics via `local_auth`).
- **Organization:** Pin favorite notes, powerful search functionality, and delete management.
- **Customizable Appearance:** Light & Dark mode support, dynamic background images, and custom note colors (Classic, Minimalist, Tinted Pastel designs).
- **Responsive Layouts:** Beautiful masonry grid layouts using `flutter_staggered_grid_view`.
- **Cloud Sync:** Backend integration powered by Appwrite for data synchronization.
- **Sharing:** Easily share your notes with others.

## 🛠️ Tech Stack & Architecture

- **Framework:** [Flutter](https://flutter.dev/)
- **State Management:** [GetX](https://pub.dev/packages/get)
- **Architecture:** MVC (Model-View-Controller) Pattern
- **Local Storage:** `sqflite` (SQLite) & `shared_preferences`
- **Backend/BaaS:** `appwrite`
- **Typography & UI:** `google_fonts`, `cupertino_icons`

## 📦 Key Dependencies

- `get` - State management, routing, and dependency injection.
- `flutter_quill` & `flutter_quill_extensions` - Rich text editor.
- `sqflite` - Local SQLite database for offline storage.
- `appwrite` - Cloud backend integration.
- `pin_code_fields` & `local_auth` - Security and authentication.
- `image_picker` & `image_cropper` - Media handling.
- `flutter_staggered_grid_view` - Staggered UI layouts.
- `share_plus` - Sharing capabilities.

## ⚙️ Getting Started

### Prerequisites

- Flutter SDK (v3.7.2 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Xcode (for iOS development)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/my_note_app.git
   cd my_note_app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## 📱 Screenshots
*(Add your screenshots here)*

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/your-username/my_note_app/issues).

## 📄 License

This project is licensed under the MIT License.
