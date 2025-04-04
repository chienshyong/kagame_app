import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // for DefaultFirebaseOptions

import '../../services/auth_service.dart';
import 'assets/my_flutter_app_icons.dart';  // Import your generated icon class
import 'app_theme.dart'; // Import the app theme file

// Page imports
import 'login.dart';
import 'register.dart';
import 'wardrobe/wardrobe_page.dart'; 
import 'wardrobe/category_page.dart';
import 'wardrobe/item_page.dart';
import 'wardrobe/recommend_page.dart';
import 'wardrobe/search_page.dart';
import 'add/add.dart';
import 'profile/profile.dart';
import 'shop/shop_page.dart';
import 'profile/stylequiz.dart';

void main() async {
  // Init firebase for google authentication
  WidgetsFlutterBinding.ensureInitialized();
  // Platform-specific Firebase initialization
  if (Platform.isIOS || Platform.isMacOS) {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  } else {
    await Firebase.initializeApp();
  }
  
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
    redirect: (BuildContext context, GoRouterState state) async {
      final token = await AuthService().getToken();
      final isLoggedIn = token != null;
      final isLoginRoute = state.uri.toString() == '/login';
      final isRegisterRoute = state.uri.toString() == '/register';
      
      if (!isLoggedIn && !isLoginRoute && !isRegisterRoute) return '/login';
      if (isLoggedIn && (isLoginRoute || state.uri.toString() == '/')) return '/wardrobe';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => NoTransitionPage(
          child: LoginPage(),
        ),
      ),

      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => NoTransitionPage(
          child: RegisterPage(),
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
                  child: ProfilePage(
                    initialEditing: state.uri.queryParameters['initialEditing'] == 'true',
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'quiz',
                    builder: (context, state) {
                      final gender = state.extra as String? ?? '';
                      return QuizPage(gender: gender);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: Text('Page Not Found')),
      body: Center(child: 
        Column(
          children: [
            Text('The page you are looking for does not exist.'),

            SizedBox(height: 8),

            // TextButton(
            //   onPressed: () => context.go('/wardrobe'),
            //   child: Text('Back to Wardrobe'),
            // ),
          ]
        ),
      ),
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
      theme: AppTheme.themeData, 
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
                icon: Icon(MyFlutterApp.tshirt_with_wand, size: 24),
                // icon: Icon(Icons.chrome_reader_mode_outlined)),
                // icon: Icon(Icons.all_inbox)), // alternative icon
            ),
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
