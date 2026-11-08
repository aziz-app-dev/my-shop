# My Shop — POS & Shop Management App

<p align="center">
  <img src="assets/app_offlical_logo.png" alt="My Shop logo" width="180" />
</p>

A cross-platform **Point of Sale (POS) and shop management** application built with Flutter. My Shop lets a shop owner manage products, sales, billing, customers, repairs, expenses and inventory from a single app that runs on desktop and mobile.

The app is **offline-first**: it stores everything in a local Hive database on each device, so it works with no internet connection at all. It keeps full-speed performance on phones by decoding images at display size instead of loading multi-megapixel camera photos.

---

## ✨ Features

- **Dashboard** — sales analytics and charts (`fl_chart`) at a glance.
- **Products & Inventory** — add/edit products, brands, categories, images.
- **Sales & Multi-Cart** — run multiple carts simultaneously (see [MULTI_CART_GUIDE.md](MULTI_CART_GUIDE.md)).
- **Keyboard-first selling** (desktop) — the search bar auto-focuses, `Tab`/arrow keys walk the product grid with a visible highlight, `Enter` adds the selected item (or a single search result), `Ctrl+Enter` completes the sale, and `Ctrl+Enter` also submits the checkout screen.
- **Walk-in checkout** — a fast payment form: customer name, address and phone are optional, paid amount and discount sit right where you need them, and an empty name means a walk-in customer.
- **Billing & Printing** — generate PDF invoices and print to thermal/regular printers.
- **Customers** — customer records, history and configurable checkout fields.
- **Repairs** — track repair jobs.
- **Expenses** — record and review shop expenses.
- **Shopping List** — restock planning (see [SHOPPING_LIST_IMPLEMENTATION_GUIDE.md](SHOPPING_LIST_IMPLEMENTATION_GUIDE.md)).
- **Barcode Scanning** — scan products via `mobile_scanner`, or use a USB barcode scanner into the search box on desktop.
- **Customizable Home Screen** — reorder/hide sections and manage a banner carousel (auto-scroll, timing) from Settings → Home Screen Management. Picked banner images are copied into the app's data folder so they persist.
- **Theming** — light/dark mode with a customizable primary color.

---

## 🧱 Tech Stack

| Concern            | Choice                                                        |
| ------------------ | ------------------------------------------------------------- |
| Framework          | Flutter (Dart SDK `^3.7.0`)                                   |
| State management   | Riverpod (`flutter_riverpod`, `StateNotifierProvider`)        |
| Local persistence  | Hive (offline-first, per-device)                              |
| Cloud backend      | Firebase Cloud Firestore **wired but inactive** — sync helpers exist in `lib/view_models/services/sync/` and re-activate automatically once a user identity is added |
| Image hosting      | Cloudinary (optional; falls back to local file paths)         |
| Responsive sizing  | `flutter_screenutil` (design size 360×690)                    |
| Charts             | `fl_chart`                                                    |
| PDF / Printing     | `pdf`, `printing`, `thermal_printer`                          |
| Design system      | Material 3, `google_fonts`, custom components                 |

> **Note on multi-device data:** with sync inactive, each device keeps its own
> database and settings (products entered on the desktop stay on the desktop,
> and vice-versa). Adding a sign-in identity to `FirebaseService` is all that's
> needed to turn the existing sync on.

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
├── utils/                    # app_sizes.dart (breakpoints), platform_utils, helpers
├── view/                     # Screens: home, sales, bills, products,
│   │                         #          customers, repairs, expenses, settings…
│   └── widgets/              # Shared widgets (ProductCard, AppCachedImage…)
└── view_models/
    ├── providers/            # Riverpod StateNotifierProviders
    ├── states/               # Immutable state classes
    └── services/             # database (Hive), firebase, sync, cloudinary,
                              # theme, image_cache, keyboard, notifications…
```

**Responsive breakpoints** (`lib/utils/app_sizes.dart`): mobile `<600`, tablet `600–1100`, desktop `≥1100`.

---

## 🖥️ Supported Platforms

Android · iOS · Windows · macOS · Linux · Web

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `^3.7.0`)
- Optional: a Firebase project (see below) if you want cloud features

### 1. Clone & install dependencies

```bash
git clone https://github.com/aziz-app-dev/my-shop.git
cd my-shop
flutter pub get
```

### 2. (Optional) Configure Firebase

The app boots fine without Firebase — `main.dart` initializes it defensively and
continues offline if config is missing. To enable the cloud side:

```bash
flutterfire configure
```

This generates `lib/firebase_options.dart` and the native config
(`android/app/google-services.json`, etc.). Then lock your **Firestore security
rules** so data is scoped to a user, e.g.:

```
match /users/{uid}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```

### 3. (Optional) Configure Cloudinary for cloud-hosted images

Copy the template and fill in your Cloudinary credentials:

```bash
cp lib/res/app_url/app_url.example.dart lib/res/app_url/app_url.dart
```

Get the cloud name / API key / API secret from **Cloudinary Dashboard →
Settings → Access Keys**, and create an unsigned upload preset under
**Settings → Upload → Upload presets**. If you skip this, images are stored as
local file paths and everything still works.

> **Do not commit real secrets.** `app_url.dart` and the Firebase config files
> are gitignored — keep credentials out of version control.

### 4. Run

```bash
# Desktop
flutter run -d windows      # or macos / linux

# Mobile
flutter run -d android      # or an attached iOS device
```

On phones, prefer **release builds** — `flutter run --release` — debug builds
are several times slower and make the app feel laggy even when the code is fine.

---

## 🔨 Build

```bash
flutter build windows       # Windows desktop
flutter build apk --release # Android
flutter build ios           # iOS
flutter build web           # Web
flutter build macos         # macOS
flutter build linux         # Linux
```

### App icons

The official logo lives at `assets/app_offlical_logo.png` and is copied to
`assets/my-shop-1024.png`, the single source the icon generator reads.
Launcher-icon config is in `flutter_launcher_icons.yaml`. After changing the
logo, regenerate every platform's icons with:

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
- **Logo:** `assets/app_offlical_logo.png` (splash, launcher icons and this README)
- **Components:** reuse `lib/res/components/` (`CustomTextField`, `AppDropdown`, `AppButton`, `AppBarWidget`, `AppFlushbar`, `AppIcon`) rather than inventing new primitives.
- **Sizing:** `flutter_screenutil` — prefer `.spMin` for sizes and gaps.
- **Images:** always pass a `cacheWidth`/`cacheHeight` to `Image.file` so thumbnails don't decode full camera photos.

---

## 📄 License

This project is currently unlicensed / private. Add a license here if you intend to distribute it.
