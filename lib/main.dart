import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Page imports
import 'login.dart';
import 'wardrobe/wardrobe_page.dart';
import 'wardrobe/category_page.dart';
import 'wardrobe/item_page.dart';
import 'wardrobe/recommend_page.dart';
import 'wardrobe/search_page.dart';
import 'add/add.dart';
import 'profile/profile.dart';
import 'shop/shop_page.dart'; 

void main() {
  // Private navigators
  final _rootNavigatorKey =
      GlobalKey<NavigatorState>(); // Index of current tab in bottom navigator
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
                    GoRoute(
                      path: 'recommend/:id',
                      builder: (context, state) {
                        final id = state.pathParameters['id'];
                        return RecommendPage(id: id!);
                      },
                    ),
                    GoRoute(
                      path: 'search/:query',
                      builder: (context, state) {
                        final query = state.pathParameters['query'];
                        return SearchPage(query: query!);
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
                  child: MultiImagePickerPage(),
                ),
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
                  child: ShopPage(),
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
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: Text('Page Not Found')),
      body: Center(child: Text('The page you are looking for does not exist.')),
    ),
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
      theme: ThemeData(
        primarySwatch: Colors.blue, // Changes primary color
        scaffoldBackgroundColor: Colors.white, // Background color
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white, // Background color of NavigationBar
          elevation: 10, // Adds a shadow effect
          indicatorColor: Colors.black12, // Selection indicator color
          
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return IconThemeData(
                  color: Colors.black, // Color when selected
                  size: 30, // Large icon when selected
                );
              }
              return IconThemeData(
                color: Colors.grey, // Color when unselected
                size: 24, // Smaller icon when unselected
              );
            },
          ),
        )
      ),
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
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected, // Only show selected label
          destinations: const [
            NavigationDestination(
                label: 'My Wardrobe',
                icon: Icon(Icons.chrome_reader_mode_outlined)),
                // icon: Icon(Icons.all_inbox)), // alternative icon
            NavigationDestination(
                label: 'Add Clothes', 
                icon: Icon(Icons.library_add)),
            NavigationDestination(
                label: 'Shop', 
                icon: Icon(Icons.shopping_cart)),
            NavigationDestination(
                label: 'Profile', 
                icon: Icon(Icons.person)),
          ],
          onDestinationSelected: _goBranch,
        ),
      ),
    );
  }
}
