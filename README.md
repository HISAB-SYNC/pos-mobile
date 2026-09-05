# HISAB POS Mobile 🚀

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Feature--Driven-22c55e)](#project-architecture)
[![License](https://img.shields.io/badge/License-Proprietary-blue.svg)](#license)

A modern, high-performance, offline-resilient **Point of Sale (POS), Inventory & Business Management System** built with **Flutter**. Engineered specifically for retailers, supermarkets, boutiques, and multi-branch commercial enterprises.

---

## 📖 Table of Contents

- [Key Features](#-key-features)
  - [1. Role-Based Access Control (RBAC)](#1-role-based-access-control-rbac)
  - [2. POS Checkout & Sales Terminal](#2-pos-checkout--sales-terminal)
  - [3. Staff & Team Management](#3-staff--team-management)
  - [4. Store Expense Tracking](#4-store-expense-tracking)
  - [5. Inventory & Stock Auditing](#5-inventory--stock-auditing)
  - [6. Reports & Financial Analytics](#6-reports--financial-analytics)
  - [7. Flexible Tax & Multi-Currency Localization](#7-flexible-tax--multi-currency-localization)
- [Project Architecture](#-project-architecture)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [API Configuration](#api-configuration)
  - [Running the App](#running-the-app)
- [Building for Production](#-building-for-production)
- [Testing & Quality Assurance](#-testing--quality-assurance)
- [Maintainers & Support](#-maintainers--support)

---

## ✨ Key Features

### 1. Role-Based Access Control (RBAC)
Tailored user interfaces designed specifically for organizational hierarchy:
* **SuperAdmin**: Platform-level oversight, shop owner provisioning via secure endpoints (`/admin/owners`).
* **Shop Owner**: Comprehensive management across multiple shops. Switch branches on the fly, access executive P&L analytics, configure tax policies, and manage store administrators.
* **Shop Admin**: Focused on single-branch store operations: stock adjustments, cashier staff management, expense logging, supplier directories, and operational thresholds.
* **Sales / Cashier**: High-speed, distraction-free checkout experience. Restricted from sensitive financial metrics and management views; optimized 100% for rapid scanning, cart adjustments, and tendering payments.

### 2. POS Checkout & Sales Terminal
* **Fast Catalog Navigation**: Interactive category tabs, instant live search, and visual product cards.
* **Interactive Cart Steppers**: Quick in-place quantity adjustments and real-time total updates.
* **Multi-Tender Payments**: Native support for **Cash**, **Card**, and **Mobile / Digital Payments** (including TeleBirr).
* **Credit Sales & Customer CRM**: Assign transactions to registered customers, track outstanding credit balances, and review purchase histories.
* **Digital & PDF Receipts**: Generate, preview, and print formatted 80mm/58mm thermal receipts with QR codes and store headers.

### 3. Staff & Team Management
* Live sync with Muhammed's backend (`/shops/:shopId/staff`).
* Assign and regulate roles (`Shop Admin` vs. `Shop Sale`).
* Deactivate or remove staff members with automatic cache invalidation.
* Live summary metrics displaying active headcount and cashier allocations.

### 4. Store Expense Tracking
* Transitioned from mock data to real backend endpoints (`/shops/:shopId/expenses`).
* Categorize overheads: **Rent**, **Utilities**, **Salaries**, **Inventory**, **Equipment**, **Marketing**, and **Other**.
* Record payment methods, dates, descriptions, and track payment status (Paid, Pending, Overdue).
* Resilient offline caching with fallback synchronization.

### 5. Inventory & Stock Auditing
* Real-time stock levels with low-stock warnings and product expiry notifications.
* Formal stock adjustment workflows with audit reasons (Damage, Restock, Return, Shrinkage, Correction).
* Support for SKU codes, barcodes, wholesale/retail pricing, and supplier associations.

### 6. Reports & Financial Analytics
* Visual revenue, profit, and order volume trend charts.
* Category sales breakdown and top-performing item highlights.
* Discount metrics tracking and formatted PDF report export.

### 7. Flexible Tax & Multi-Currency Localization
* **Custom Tax Control**: Because tax regulations vary widely by material and product, the default tax rate is set to `0.0%` and is fully editable.
* **Per-Shop Local Persistence**: Custom tax percentages are preserved locally on the device and never wiped by remote backend fetches.
* **On-the-Fly Checkout Override**: Cashiers can set or adjust the tax percentage directly on the checkout screen for specific sales.
* **Multi-Currency Support**: Native currency formatting with primary support for **ETB** (Ethiopian Birr), USD, EUR, and GBP.

---

## 🏛 Project Architecture

The project follows a **Feature-First Clean Architecture**, ensuring high modularity, testability, and separation of concerns:

```text
lib/
├── core/                         # Shared core infrastructure
│   ├── models/                   # Global models (AppUser, etc.)
│   ├── navigation/               # Shell navigation, store switcher, drawer
│   ├── network/                  # ApiClient, HTTP interceptors, token handling
│   ├── services/                 # PDF generators, receipt services, scope helpers
│   ├── theme/                    # Color palette, typography, AppDecorations
│   └── widgets/                  # Reusable UI widgets (steppers, skeletons, empty states)
├── features/                     # Feature modules
│   ├── auth/                     # Authentication, login, SuperAdmin owner provisioning
│   ├── cart/                     # Cart state, subtotal computations
│   ├── catalog/                  # Product catalog grid & filtering
│   ├── category/                 # Category management
│   ├── customer/                 # Customer directory & credit tracking
│   ├── dashboard/                # Scoped dashboards (Owner, Admin, Sales)
│   ├── expenses/                 # Store expense management & repository
│   ├── orders/                   # Sales history, detail sheets, order repository
│   ├── product/                  # Product creation, adjustments, barcode handling
│   ├── reports/                  # Financial charts, PDF reports, analytics models
│   ├── sales/                    # Checkout flow, payment methods, receipts
│   ├── settings/                 # Shop preferences, local tax configuration, profile
│   ├── shop/                     # Shop models, creation sheet, ShopProvider
│   ├── staff/                    # Staff management, role assignment, repository
│   └── supplier/                 # Supplier directory & management
└── main.dart                     # App entry point & provider declarations
```

---

## 🚀 Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.3.0`)
* [Dart SDK](https://dart.dev/get-dart) (`>= 3.3.0`)
* Android Studio / Xcode / VS Code with Flutter extension
* Android device or emulator (Android 7.0+ / API 24+)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/HISAB-SYNC/pos-mobile.git
   cd pos-mobile
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

### API Configuration
The network layer targets Muhammed's NestJS backend API:
```dart
// lib/core/network/api_client.dart
class ApiClient {
  static const String baseUrl = 'https://pos-backend-0fzk.onrender.com';
  ...
}
```

### Running the App
* **Android / iOS Device**:
  ```bash
  flutter run
  ```
* **Chrome (with Web Security disabled for local CORS bypass)**:
  ```bash
  flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=/tmp/chrome_dev"
  ```
* **Desktop (Linux / macOS / Windows)**:
  ```bash
  flutter run -d linux
  ```

---

## 📦 Building for Production

### Android (APK & App Bundle)
```bash
# Build universal APK
flutter build apk --release

# Build split APKs per ABI
flutter build apk --split-per-abi --release

# Build Google Play App Bundle
flutter build appbundle --release
```
Artifacts will be located under `build/app/outputs/flutter-apk/` and `build/app/outputs/bundle/release/`.

### iOS
```bash
flutter build ipa --release
```

---

## 🧪 Testing & Quality Assurance

Run static analysis to verify code styling, typing, and zero compile errors:
```bash
flutter analyze
```

Run automated test suites:
```bash
flutter test
```

---

## 👥 Maintainers & Support

* **Engineering Team**: HISAB-SYNC Engineering
* **Repository**: [github.com/HISAB-SYNC/pos-mobile](https://github.com/HISAB-SYNC/pos-mobile)

For bug reports, feature requests, or deployment inquiries, please contact the development team or open a GitHub issue.
