# BetterLife

BetterLife is a Flutter application for tracking everyday finance and health data. Users can register, sign in, track income, expenses, budget limits, saving goals, assets, calories, steps, and habits. Some data is stored in Firebase services, and food search uses external USDA data.

## Team Members

Team members:

- Edgaras Borisevičius
- Titas Baginas
- Orestas Stelmokas
- Martynas Kregždė
- Gvidas Mažeika

## Technical Task

Create a mobile personal life tracking application that helps users manage financial and health-related data in one place.

Main requirements:

- user registration, sign-in, sign-out, and password reset;
- cloud storage for individual user data;
- finance modules: income, expenses, monthly budgets, saving goals, assets, and investments;
- health modules: calorie entries, step tracking, and habit tracking;
- food product search using the USDA database;
- receipt scanning using an image, OCR, and expense recognition;
- automated tests for models, services, and main UI scenarios.

## Technologies Used

- Flutter / Dart - user interface and application logic.
- Firebase Core, Firebase Auth - authentication and Firebase initialization.
- Cloud Firestore - storage for user finance and health data.
- `fl_chart` - charts and financial summaries.
- `http` - requests to the USDA food data API.
- `google_mlkit_text_recognition` and `image_picker` - receipt image selection and OCR.
- `flutter_test`, `fake_cloud_firestore` - automated testing.

## Architecture

The project is a Flutter application. The main source code is located in `BetterLife/better_life/lib`.

Main parts:

- `main.dart` - application startup, Firebase initialization, and authentication gate.
- `pages/` - user interface screens: home page, sign-in, sign-up, finance, health, calories, steps, receipt scanner, and others.
- `pages/widgets/` - reusable UI components, such as entry creation bottom sheets and the profile action button.
- `models/` - data models: expenses, income, budgets, calories, assets, goals, and scanned receipt results.
- `services/` - business logic and integrations with Firebase, USDA API, OCR, and receipt text parsing.
- `theme/` - color palette, themes, and theme management.
- `test/` - automated tests.

Data flow:

1. The user signs in through Firebase Auth.
2. `AuthGate` redirects the user to either the sign-in screen or the main screen based on authentication state.
3. UI pages call the corresponding services from `services/`.
4. Services read and write user data to Firestore or call external services.
5. Screens update through `StreamBuilder` when Firestore data changes.

## Testing and Results

Tests are located in `BetterLife/better_life/test`.

Tested areas:

- model validation and calculations;
- adding and deleting budget limits;
- income and expense page scenarios;
- calorie entries;
- health / goal / asset models;
- USDA food search result processing;
- receipt text parsing.

Run tests:

```bash
cd BetterLife/better_life
flutter test
```

Current verification:

- 11 test files were found in the `test/` directory;
- `flutter test` was started and all tests passed.

## Short User Documentation

### Running the Project

1. Install Flutter SDK and the required platform tools.
2. Open the project directory:

```bash
cd BetterLife/better_life
```

3. Install dependencies:

```bash
flutter pub get
```

4. Run the application:

```bash
flutter run
```

### Signing In

When the application opens, the user is redirected to the sign-in screen. The user can:

- sign in with an existing account;
- create a new account;
- reset the password by email;
- use the temporary development sign-in if it is still enabled in the code.

### Finance Usage

In the `Finances` section, the user can:

- view a monthly income and expense summary;
- add expenses;
- add and view income;
- create monthly budget limits;
- track saving goals;
- register assets and investments;
- scan a receipt from an image and create an expense entry from the recognized text.

### Health Usage

In the `Health` section, the user can:

- register calorie entries;
- search for food products in the USDA database;
- track steps by day and month;
- set a daily step goal;
- track habits.
