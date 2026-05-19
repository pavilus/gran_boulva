import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/create_account_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/matchups/matchups_feed_screen.dart';
import '../screens/matchups/matchup_detail_screen.dart';
import '../screens/predictions/predictions_feed_screen.dart';
import '../screens/predictions/prediction_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/public_profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/boost/boost_selection_screen.dart';
import '../screens/boost/payment_screen.dart';
import '../screens/badges/badges_screen.dart';
import '../screens/coins/coin_store_screen.dart';
import '../screens/invite/invite_friends_screen.dart';
import '../screens/home/menu_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/profile/personal_info_screen.dart';
import '../screens/profile/security_screen.dart';
import '../screens/profile/notification_settings_screen.dart';
import '../screens/profile/help_screen.dart';
import 'app_colors.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final loc = state.matchedLocation;

      final publicRoutes = [
        '/splash',
        '/login',
        '/create-account',
        '/forgot-password'
      ];
      final isPublic = publicRoutes.any((r) => loc.startsWith(r));

      if (isAuth && isPublic && loc != '/splash') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/create-account',
          builder: (_, s) =>
              CreateAccountScreen(referralCode: s.uri.queryParameters['ref'])),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),

      // Main shell with bottom nav
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
              path: '/matchups',
              builder: (_, __) => const MatchupsFeedScreen()),
          GoRoute(
              path: '/predictions',
              builder: (_, __) => const PredictionsFeedScreen()),
          GoRoute(
              path: '/notifications',
              builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/menu', builder: (_, __) => const MenuScreen()),
        ],
      ),

      // Full-screen routes (no bottom nav)
      GoRoute(
        path: '/matchup/:id',
        builder: (_, s) => MatchupDetailScreen(
          matchupId: s.pathParameters['id']!,
          initialVoteOptionId: s.uri.queryParameters['voted'],
        ),
      ),
      GoRoute(
        path: '/prediction/:id',
        builder: (_, s) =>
            PredictionDetailScreen(predictionId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/user/:username',
        builder: (_, s) =>
            PublicProfileScreen(username: s.pathParameters['username']!),
      ),
      GoRoute(
        path: '/boost/:argumentId',
        builder: (_, s) =>
            BoostSelectionScreen(argumentId: s.pathParameters['argumentId']!),
      ),
      GoRoute(
        path: '/payment',
        builder: (_, s) => PaymentScreen(
          clientSecret: s.uri.queryParameters['secret'] ?? '',
          amountCents:
              int.tryParse(s.uri.queryParameters['amount'] ?? '100') ?? 100,
          tierLabel: s.uri.queryParameters['label'] ?? '',
          argumentId: s.uri.queryParameters['argumentId'] ?? '',
        ),
      ),
      GoRoute(path: '/invite', builder: (_, __) => const InviteFriendsScreen()),
      GoRoute(path: '/badges', builder: (_, __) => const BadgesScreen()),
      GoRoute(path: '/coins', builder: (_, __) => const CoinStoreScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(
          path: '/personal-info',
          builder: (_, __) => const PersonalInfoScreen()),
      GoRoute(path: '/security', builder: (_, __) => const SecurityScreen()),
      GoRoute(
          path: '/notification-settings',
          builder: (_, __) => const NotificationSettingsScreen()),
      GoRoute(path: '/help', builder: (_, __) => const HelpScreen()),
    ],
  );
}

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _tabs = ['/home', '/notifications', '/profile', '/menu'];

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    _currentIndex = _tabs.indexWhere((t) => loc.startsWith(t));
    if (_currentIndex < 0) _currentIndex = 0;

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: widget.child,
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          context.go(_tabs[i]);
        },
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg0,
        border: Border(top: BorderSide(color: Color(0xFF2A2A4A), width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                iconActive: Icons.home,
                iconInactive: Icons.home_outlined,
                label: 'Akèy',
                index: 0,
                current: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                iconActive: Icons.bolt,
                iconInactive: Icons.bolt_outlined,
                label: 'Aktivite',
                index: 1,
                current: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                iconActive: Icons.person,
                iconInactive: Icons.person_outline,
                label: 'Pwofil',
                index: 2,
                current: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                iconActive: Icons.apps_rounded,
                iconInactive: Icons.apps_rounded,
                label: 'Meni',
                index: 3,
                current: currentIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData iconActive;
  final IconData iconInactive;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.iconActive,
    required this.iconInactive,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    const activeColor = Color(0xFFA855F7);
    const inactiveColor = Color(0xFF4A4A6A);
    final color = isActive ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isActive ? iconActive : iconInactive,
                    color: color, size: 24),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
