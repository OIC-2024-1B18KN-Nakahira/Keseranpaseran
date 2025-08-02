import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:keseranpaseran/acount_page/login.dart';
import 'package:keseranpaseran/acount_page/account_setting.dart';
import 'package:keseranpaseran/acount_page/account_create.dart';
import 'package:keseranpaseran/setting_page/6.dart';
import 'package:keseranpaseran/setting_page/6_edit_profile.dart';
import 'package:keseranpaseran/setting_page/6_change_email.dart';
import 'package:keseranpaseran/setting_page/6_email_sent.dart';
import 'package:keseranpaseran/history.dart';
import 'package:keseranpaseran/home.dart';
import 'package:keseranpaseran/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'record.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> calendarNavigatorKey =
    GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> todoNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> homeNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> accountNavigatorKey =
    GlobalKey<NavigatorState>();

class MyApp extends ConsumerWidget {
  MyApp({super.key});

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
              GoRoute(path: '/home', builder: (context, state) => const Home()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: todoNavigatorKey,
            routes: [
              GoRoute(
                path: '/record',
                builder: (context, state) => const Record(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const History(),
              ),
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
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: _createRouter(ref),
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

  GoRouter _createRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/login',
      navigatorKey: rootNavigatorKey,
      // リダイレクト機能を追加
      redirect: (BuildContext context, GoRouterState state) {
        // 認証状態を確認
        final isAuthenticated = ref.read(isAuthenticatedProvider);
        final isLoggingIn = state.uri.toString() == '/login';
        final isCreatingAccount = state.uri.toString().startsWith(
          '/account_create',
        );

        print('=== ルートガード ===');
        print('現在のパス: ${state.uri}');
        print('認証状態: $isAuthenticated');
        print('ログインページか: $isLoggingIn');
        print('アカウント作成ページか: $isCreatingAccount');

        // 認証されていない場合
        if (!isAuthenticated) {
          // ログインページまたはアカウント作成ページでない場合はログインページにリダイレクト
          if (!isLoggingIn && !isCreatingAccount) {
            print('→ ログインページにリダイレクト');
            return '/login';
          }
        } else {
          // 認証されている場合
          // ログインページまたはアカウント作成ページにいる場合はホームページにリダイレクト
          if (isLoggingIn || isCreatingAccount) {
            print('→ ホームページにリダイレクト');
            return '/home';
          }
        }

        print('→ リダイレクトなし');
        return null; // リダイレクトしない
      },
      // リフレッシュのタイミングを制御
      refreshListenable: GoRouterRefreshStream(
        Supabase.instance.client.auth.onAuthStateChange,
      ),
      routes: [
        // 認証が必要なページ群
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
                  builder: (context, state) => const Home(),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: todoNavigatorKey,
              routes: [
                GoRoute(
                  path: '/record',
                  builder: (context, state) => const Record(),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: homeNavigatorKey,
              routes: [
                GoRoute(
                  path: '/history',
                  builder: (context, state) => const History(),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: accountNavigatorKey,
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
                    GoRoute(
                      path: 'search',
                      name: 'accountSearch',
                      builder: (context, state) => const AccountSearchPage(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        // 認証が不要なページ群
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

// GoRouterのリフレッシュ用クラス
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream stream) {
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
          navigationShell.goBranch(index);
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
