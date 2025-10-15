import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'acount_page/account_create.dart';
import 'acount_page/account_setting.dart';
import 'acount_page/login.dart';
import 'history.dart';
import 'home.dart';
import 'provider.dart';
import 'record.dart';
import 'setting_page/6.dart';
import 'setting_page/6_change_email.dart';
import 'setting_page/6_edit_profile.dart';
import 'setting_page/6_email_sent.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _recordNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _historyNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _accountNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  const AppRouter._();

  static GoRouter createRouter(Ref ref) {
    return _createRouterCore(ref.read);
  }

  static GoRouter _createRouterCore(T Function<T>(ProviderBase<T> provider) read) {
    return GoRouter(
      initialLocation: '/login',
      navigatorKey: _rootNavigatorKey,
      redirect: (BuildContext context, GoRouterState state) {
        final isAuthenticated = read(isAuthenticatedProvider);
        final isLoggingIn = state.uri.toString() == '/login';
        final isCreatingAccount = state.uri.toString().startsWith(
          '/account_create',
        );

        if (!isAuthenticated) {
          if (!isLoggingIn && !isCreatingAccount) {
            return '/login';
          }
        } else {
          if (isLoggingIn || isCreatingAccount) {
            return '/home';
          }
        }

        return null;
      },
      refreshListenable: _GoRouterRefreshStream(
        Supabase.instance.client.auth.onAuthStateChange,
      ),
      routes: [
        StatefulShellRoute.indexedStack(
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state, navigationShell) {
            return _AppNavigationBar(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              navigatorKey: _homeNavigatorKey,
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const Home(),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _recordNavigatorKey,
              routes: [
                GoRoute(
                  path: '/record',
                  builder: (context, state) => const Record(),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _historyNavigatorKey,
              routes: [
                GoRoute(
                  path: '/history',
                  builder: (context, state) => const History(),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _accountNavigatorKey,
              routes: [
                GoRoute(
                  path: '/account',
                  name: 'account',
                  builder: (context, state) => const Account(),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      name: 'editProfile',
                      builder: (context, state) => const EditProfilePage(),
                    ),
                    GoRoute(
                      path: 'change-email',
                      name: 'changeEmail',
                      builder: (context, state) => const ChangeEmailPage(),
                    ),
                    GoRoute(
                      path: 'email-sent',
                      name: 'emailSent',
                      builder: (context, state) => const EmailSentPage(),
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
  }
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _AppNavigationBar extends StatelessWidget {
  const _AppNavigationBar({
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_document),
            selectedIcon: Icon(Icons.edit_document),
            label: '記録',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: '履歴',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}