# Kagame App

## Installation

-Install Android studio https://developer.android.com/studio/install#windows
-Install Flutter from VS Code https://docs.flutter.dev/get-started/install/windows/mobile
-`flutter doctor` to check reqs (install cmdline-tools, license)
-Developed with Java (JDK) version 21, Flutter version 3.24.3, 

## Project Structure

App code is all in `/lib`.

`main.dart` is the root and implements the router, all the routes within the app, and bottom navbar.
`login.dart` is the login page.

Code is split by content, with one subfolder per navbar tab within `/lib`: Wardrobe, Recommend, Add, Shop and Profile. (TODO)

`/services` include all helper functions for calling the API.

## Navigation and Routing

Implemented [Stateful Nested Routing](https://codewithandrea.com/articles/flutter-bottom-navigation-bar-nested-routes-gorouter/) using GoRouter. This allows each navbar tab to hold its own navigation stack, remembering its route index even if the user switches to a different tab.

To create a new route, define it within `main.dart`. Navigate to a new route with `context.push('/route/:params')` (append to navigation stack) or `context.go('/route/:params')` (resets navigation stack);

## API Calls

`config.dart` includes the API base URL `10.0.2.2:8000` for development, which is a special IP that tells the android emulator that the backend is running on localhost. Change this when we deploy.

## Authentication

Upon login, access token is stored to `FlutterSecureStorage`, and cleared upon logout. Almost all API calls require the header `'Authorization': 'Bearer $token'` to identify the user.