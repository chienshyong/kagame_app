# Kagame App

## Project Structure

App code is all in `/lib`.

`main.dart` is the root and implements the router, all the routes within the app, and bottom navbar.

Code is split by content, with one subfolder per navbar tab within `/lib`: Wardrobe, Recommend, Add, Shop and Profile. (TODO)

## Navigation and Routing

Implemented [Stateful Nested Routing](https://codewithandrea.com/articles/flutter-bottom-navigation-bar-nested-routes-gorouter/) using GoRouter. This allows each navbar tab to hold its own navigation stack, remembering its route index even if the user switches to a different tab.

To create a new route, define it within `main.dart`. Navigate to a new route with `context.push('/route/:params')` (append to navigation stack) or `context.go('/route/:params')` (resets navigation stack);