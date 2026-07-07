# My Shop — POS & Shop Management App

A cross-platform **Point of Sale (POS) and shop management** application built with Flutter. My Shop lets a shop owner manage products, sales, billing, customers, repairs, expenses and inventory from a single app that runs on desktop, mobile and web.

The app works **offline-first** using a local Hive database and syncs to the cloud (Firebase Cloud Firestore) when a connection is available. Users sign in with email/password (Firebase Auth).

---

## ✨ Features

- **Dashboard** — sales analytics and charts (`fl_chart`) at a glance.
- **Products & Inventory** — add/edit products, brands, categories, images.
- **Sales & Multi-Cart** — run multiple carts simultaneously (see [MULTI_CART_GUIDE.md](MULTI_CART_GUIDE.md)).
- **Billing & Printing** — generate PDF invoices and print to thermal/regular printers.
- **Payment System** — flexible payment handling (see [PAYMENT_SYSTEM_IMPLEMENTATION.md](PAYMENT_SYSTEM_IMPLEMENTATION.md)).
- **Customers** — customer records and history.
- **Repairs** — track repair jobs.
- **Expenses** — record and review shop expenses.
- **Shopping List** — restock planning (see [SHOPPING_LIST_IMPLEMENTATION_GUIDE.md](SHOPPING_LIST_IMPLEMENTATION_GUIDE.md)).
- **Barcode Scanning** — scan products via `mobile_scanner`.
- **Authentication** — email/password login & registration (Firebase Auth) with animated screens; new users complete their full shop profile during sign-up.
- **Cloud Image Storage** — product images hosted on Cloudinary with local caching.
- **Offline-first Sync** — local Hive storage with background Cloud Firestore sync (writes queue offline and flush when online; realtime changes apply back to Hive).
- **Theming** — light/dark mode with a customizable primary color.
- **Biometric Auth** — optional local app-lock (`local_auth`).

---

## 🧱 Tech Stack

| Concern            | Choice                                                        |
| ------------------ | ------------------------------------------------------------- |
| Framework          | Flutter (Dart SDK `^3.7.0`)                                   |
| State management   | Riverpod (`flutter_riverpod`, `StateNotifierProvider`)        |
| Local persistence  | Hive (offline-first)                                          |
| Auth               | Firebase Auth (email/password)                                |
| Cloud backend      | Firebase Cloud Firestore                                      |
| Image hosting      | Cloudinary                                                    |
| Responsive sizing  | `flutter_screenutil` (design size 360×690)                    |
| Charts             | `fl_chart`                                                    |
| PDF / Printing     | `pdf`, `printing`, `thermal_printer`                          |
| Design system      | Material 3, `google_fonts`, custom components                 |

---

## 📁 Project Structure

```text
lib/
├── main.dart                 # App entry point (Firebase + Hive + cache init)
├── firebase_options.dart     # FlutterFire config (gitignored)
├── models/                   # Data models (Hive toMap/fromMap)
├── res/
│   ├── colors/               # app_color.dart — brand orange 0xFFff6701
│   ├── components/           # Reusable UI (CustomTextField, AppButton, AppDropdown…)
│   └── app_url/              # Cloudinary / API config
├── responsive/               # Responsive layout helpers
├── routes/                   # Named routes & route generation
├── utils/                    # app_sizes.dart (breakpoints), helpers
├── view/                     # Screens: dashboard, sales, bills, products,
│   │                         #          customers, repairs, expenses, settings…
│   └── widgets/              # Shared widgets
└── view_models/
    ├── providers/            # Riverpod StateNotifierProviders (incl. auth)
    ├── states/               # Immutable state classes
    └── services/             # database (Hive), firebase (auth + Firestore),
                              # sync, cloudinary, theme, image_cache…
```

**Responsive breakpoints** (`lib/utils/app_sizes.dart`): mobile `<600`, tablet `600–1100`, desktop `≥1100`.

---

## 🖥️ Supported Platforms

Android · iOS · Windows · macOS · Linux · Web

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `^3.7.0`)
- A Firebase project with **Authentication → Email/Password** enabled and a **Cloud Firestore** database
- The [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup) (`dart pub global activate flutterfire_cli`)
- A Cloudinary account (for product images)

### 1. Clone & install dependencies

```bash
git clone <your-repo-url>
cd desktopapp
flutter pub get
```

### 2. Configure Firebase

Firebase config is **gitignored** and must be generated locally per project:

```bash
flutterfire configure
```

This generates `lib/firebase_options.dart` and the native config
(`android/app/google-services.json`, etc.). Then lock your **Firestore security
rules** so data is scoped to the signed-in user, e.g.:

```
match /users/{uid}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```

### 3. Configure Cloudinary (optional — for cloud-hosted images)

Cloudinary hosts product/shop images. It is **optional**: if you skip it, image
uploads are simply not performed and the app falls back to storing local image
paths (so everything still works, images just aren't synced to the cloud).

To enable it, copy the template and fill in your Cloudinary credentials:

```bash
cp lib/res/app_url/app_url.example.dart lib/res/app_url/app_url.dart
```

Get the cloud name / API key / API secret from **Cloudinary Dashboard →
Settings → Access Keys**, and create an unsigned upload preset under
**Settings → Upload → Upload presets**.

> **Do not commit real secrets.** `app_url.dart` and the Firebase config files
> are gitignored — keep credentials out of version control.

### 4. Run

```bash
# Desktop
flutter run -d windows      # or macos / linux

# Mobile
flutter run -d android      # or an attached iOS device

# Web
flutter run -d chrome
```

---

## 🔨 Build

```bash
flutter build windows       # Windows desktop
flutter build apk           # Android
flutter build ios           # iOS
flutter build web           # Web
flutter build macos         # macOS
flutter build linux         # Linux
```

### App icons

Launcher-icon config lives in `flutter_launcher_icons.yaml`. After changing the icon:

```bash
dart run flutter_launcher_icons
```

---

## 🧪 Testing & Analysis

```bash
flutter test        # run tests
flutter analyze     # static analysis (flutter_lints)
```

---

## 📚 Additional Documentation

- [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) — overall implementation notes
- [MULTI_CART_GUIDE.md](MULTI_CART_GUIDE.md) — multi-cart sales feature
- [PAYMENT_SYSTEM_IMPLEMENTATION.md](PAYMENT_SYSTEM_IMPLEMENTATION.md) — payment system
- [SHOPPING_LIST_IMPLEMENTATION_GUIDE.md](SHOPPING_LIST_IMPLEMENTATION_GUIDE.md) — shopping list feature
- [CLAUDE.md](CLAUDE.md) — project conventions & contributor guidance

---

## 🎨 Design System

- **Brand / primary color:** orange `#FF6701`
- **Components:** reuse `lib/res/components/` (`CustomTextField`, `AppDropdown`, `AppButton`, `AppBarWidget`, `AppFlushbar`, `AppIcon`) rather than inventing new primitives.
- **Sizing:** `flutter_screenutil` — prefer `.spMin` for sizes and gaps.

---

## 📄 License

This project is currently unlicensed / private. Add a license here if you intend to distribute it.
