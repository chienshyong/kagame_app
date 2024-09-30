import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Page imports
import 'login.dart';
import 'home/home_page.dart';
import 'wardrobe/wardrobe_page.dart';
import 'wardrobe/category_page.dart';
import 'wardrobe/item_page.dart';
import 'add/camera.dart';
import 'add/image_editor.dart';
import 'add/into_wardrobe.dart';
import 'profile/profile.dart';

void main() {
  // Private navigators
  final _rootNavigatorKey =
      GlobalKey<NavigatorState>(); // Index of current tab in bottom navigator
  final _homeShellKey = GlobalKey<NavigatorState>(debugLabel:'shellH');
  final _wardrobeShellKey = GlobalKey<NavigatorState>(debugLabel: 'shellW');
  final _addShellKey = GlobalKey<NavigatorState>(debugLabel: 'shellA');
  final _shopShellKey = GlobalKey<NavigatorState>(debugLabel: 'shellS');
  final _profileShellKey = GlobalKey<NavigatorState>(debugLabel: 'shellP');

  // The one and only GoRouter instance. Defines all routes in the app.
  final goRouter = GoRouter(
    initialLocation: '/login',
    navigatorKey: _rootNavigatorKey,
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => NoTransitionPage(
          child: LoginPage(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // the UI shell
          return ScaffoldWithNestedNavigation(
            navigationShell: navigationShell,
          );
        },
        branches: [
          // first branch (Home)
          StatefulShellBranch(
            navigatorKey: _homeShellKey,
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: HomePage(),
                ),
              ),
            ],
          ),
          // second branch (Wardrobe)
          StatefulShellBranch(
            navigatorKey: _wardrobeShellKey,
            routes: [
              GoRoute(
                  path: '/wardrobe',
                  pageBuilder: (context, state) => NoTransitionPage(
                        child: WardrobePage(),
                      ),
                  routes: [
                    GoRoute(
                      path: 'category/:category',
                      builder: (context, state) {
                        final category = state.pathParameters['category'];
                        return CategoryPage(category: category!);
                      },
                    ),
                    GoRoute(
                      path: 'item/:id',
                      builder: (context, state) {
                        final id = state.pathParameters['id'];
                        return ItemPage(id: id!);
                      },
                    ),
                  ]),
            ],
          ),
          // third branch (Add)
          StatefulShellBranch(
            navigatorKey: _addShellKey,
            routes: [
              GoRoute(
                path: '/add',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: CameraPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'editor/:encodedImagePath',
                    builder: (context, state) {
                      final encodedImagePath =
                          state.pathParameters['encodedImagePath']!;
                      final imagePath = Uri.decodeComponent(encodedImagePath);
                      return ImageEditorPage(imagePath: imagePath);
                    },
                  ),
                  GoRoute(
                    path: 'into_wardrobe/:encodedImagePath',
                    builder: (context, state) {
                      final encodedImagePath =
                          state.pathParameters['encodedImagePath']!;
                      final imagePath = Uri.decodeComponent(encodedImagePath);
                      final jsonResponse = state.extra as Map<String, dynamic>;
                      return IntoWardrobePage(
                          imagePath: imagePath, jsonResponse: jsonResponse);
                    },
                  ),
                ],
              ),
            ],
          ),
          // fourth branch (Shop)
          StatefulShellBranch(
            navigatorKey: _shopShellKey,
            routes: [
              GoRoute(
                path: '/shop',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: Placeholder(),
                ),
              ),
            ],
          ),
          // fifth branch (Profile)
          StatefulShellBranch(
            navigatorKey: _profileShellKey,
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: ProfilePage(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  runApp(MyApp(router: goRouter));
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  const MyApp({required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
    );
  }
}

// Stateful nested navigation
class ScaffoldWithNestedNavigation extends StatelessWidget {
  const ScaffoldWithNestedNavigation({
    Key? key,
    required this.navigationShell,
  }) : super(key: key ?? const ValueKey('ScaffoldWithNestedNavigation'));
  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          destinations: const [
            NavigationDestination(label: 'Home', icon: Icon(Icons.home)),
            NavigationDestination(
                label: 'Wardrobe',
                icon: Icon(Icons.chrome_reader_mode_outlined)),
            NavigationDestination(label: 'Add', icon: Icon(Icons.library_add)),
            NavigationDestination(
                label: 'Shop', icon: Icon(Icons.shopping_cart)),
            NavigationDestination(label: 'Profile', icon: Icon(Icons.person)),
          ],
          onDestinationSelected: _goBranch,
        ),
      ),
    );
  }
}
