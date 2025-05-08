import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:keseranpaseran/3.dart';
import 'package:keseranpaseran/4.dart';
import 'package:keseranpaseran/5.dart';
import 'package:keseranpaseran/6.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> calendarNavigatorKey =
    GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> todoNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> homeNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> accountNavigatorKey =
    GlobalKey<NavigatorState>();

class AppRouter extends StatelessWidget {
  AppRouter({super.key});

  final router = GoRouter(
    initialLocation: '/home',
    navigatorKey: rootNavigatorKey,
    routes: [
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return AppNavigationBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: calendarNavigatorKey,
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const Calender(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: todoNavigatorKey,
            routes: [
              GoRoute(path: '/todo', builder: (context, state) => const Todo()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: homeNavigatorKey,
            routes: [
              GoRoute(path: '/home', builder: (context, state) => const Home()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: accountNavigatorKey,
            routes: [
              GoRoute(
                path: '/account',
                builder: (context, state) => const Account(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 239, 239, 239),
        ),
        useMaterial3: false,
        primaryIconTheme: const IconThemeData(color: Colors.black),
      ),
    );
  }
}

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(index); // インデックスに基づいて画面を切り替える
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            label: 'カレンダー',
            selectedIcon: const Icon(Icons.calendar_today),
          ),
          NavigationDestination(
            icon: const Icon(Icons.checklist_outlined),
            label: 'Todo',
            selectedIcon: const Icon(Icons.checklist),
          ),
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: 'ホーム',
            selectedIcon: const Icon(Icons.home),
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_circle_outlined),
            label: 'アカウント',
            selectedIcon: const Icon(Icons.account_circle),
          ),
        ],
      ),
    );
  }
}
