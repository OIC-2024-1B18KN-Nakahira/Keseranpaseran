import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:keseranpaseran/1/1.dart';
import 'package:keseranpaseran/1/1_account_create.dart';
import 'package:keseranpaseran/1/2_account_create2.dart';
import 'package:keseranpaseran/3.dart';
import 'package:keseranpaseran/4.dart';
import 'package:keseranpaseran/5.dart';
import 'package:keseranpaseran/6/6.dart';
import 'package:keseranpaseran/6/6_edit_profile.dart';
import 'package:keseranpaseran/6/6_change_email.dart';
import 'package:keseranpaseran/6/6_email_sent.dart';
import 'package:keseranpaseran/6/6_search.dart';
import 'record.dart';

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
    initialLocation: '/login',
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
                path: '/home',
                builder: (context, state) => const Calender(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: todoNavigatorKey,
            routes: [
              GoRoute(
                path: '/recod',
                builder: (context, state) => const Record(),
              ),
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
              /// 6  (ルート画面)
              GoRoute(
                path: '/account',
                name: 'account', // ← name を付けておくと便利
                builder: (context, state) => const Account(),
                routes: [
                  /// 6.1
                  GoRoute(
                    path: 'edit', // => /account/edit
                    name: 'editProfile',
                    builder: (context, state) => const EditProfilePage(),
                  ),

                  /// 6.2
                  GoRoute(
                    path: 'change-email', // => /account/change-email
                    name: 'changeEmail',
                    builder: (context, state) => const ChangeEmailPage(),
                  ),

                  /// 6.3 (完了ダイアログ画面)
                  GoRoute(
                    path: 'email-sent', // => /account/email-sent
                    name: 'emailSent',
                    builder: (context, state) => const EmailSentPage(),
                  ),

                  /// 6.4
                  GoRoute(
                    path: 'search', // => /account/search
                    name: 'accountSearch',
                    builder: (context, state) => const AccountSearchPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/account_create',
        name: 'accountCreate',
        builder: (context, state) => const AccountCreate(),
      ),
      GoRoute(
        path: '/account_create2',
        name: 'accountCreate2',
        builder: (context, state) => const AccountCreate2(),
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
        primaryIconTheme: const IconThemeData(color: Colors.black),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          toolbarHeight: 80,
        ),
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
            icon: const Icon(Icons.home_outlined),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: const Icon(Icons.edit_document),
            label: '記録',
          ),
          NavigationDestination(icon: const Icon(Icons.menu_book), label: '履歴'),
          NavigationDestination(icon: const Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}
