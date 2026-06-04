import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/create_account_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/matchups/matchups_feed_screen.dart';
import '../screens/matchups/matchup_detail_screen.dart';
import '../screens/predictions/predictions_feed_screen.dart';
import '../screens/predictions/prediction_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/my_statistics_screen.dart';
import '../screens/profile/public_profile_screen.dart';
import '../screens/profile/recent_activity_screen.dart';
import '../screens/profile/saved_matchups_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/profile/subscriptions_screen.dart';
import '../screens/profile/top_voices_screen.dart';
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
import '../screens/profile/verification_request_screen.dart';
import '../screens/profile/creator_dashboard_screen.dart';
import '../screens/profile/streak_recovery_screen.dart';
import '../screens/cosmetics/cosmetics_store_screen.dart';
import '../screens/battles/battle_screen.dart';
import '../screens/battles/battle_challenge_screen.dart';
import '../screens/battles/battle_incoming_screen.dart';
import '../screens/battles/battle_lobby_screen.dart';
import '../screens/battles/battle_live_screen.dart';
import '../screens/battles/battle_result_screen.dart';
import '../screens/battles/battle_replay_screen.dart';
import '../screens/media/media_feed_screen.dart';
import '../widgets/common/app_interactions.dart';
import 'app_colors.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// Loads and caches the signed-in user's role so the router can redirect
// non-admins away from /admin without waiting for the screen to mount.
class _AuthState extends ChangeNotifier {
  String? _role;
  String? get role => _role;
  bool _loaded = false;
  bool get loaded => _loaded;

  _AuthState() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) => _loadRole());
    _loadRole();
  }

  Future<void> _loadRole() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      _role = null;
      _loaded = true;
      notifyListeners();
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('auth_user_id', uid)
          .maybeSingle();
      _role = data?['role'] as String?;
    } catch (_) {
      _role = null;
    }
    _loaded = true;
    notifyListeners();
  }
}

GoRouter createRouter() {
  final authState = _AuthState();
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authState,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final uri = state.uri;
      if (uri.scheme == 'granboulva' && uri.host == 'auth-callback') {
        if (isAuth) return '/home';
        final errorCode = uri.queryParameters['error_code'] ??
            uri.fragment
                .split('&')
                .map((part) => part.split('='))
                .firstWhere(
                  (pair) => pair.length == 2 && pair.first == 'error_code',
                  orElse: () => const ['', ''],
                )
                .last;
        return Uri(
          path: '/login',
          queryParameters: errorCode.isEmpty ? null : {'auth_error': errorCode},
        ).toString();
      }

      final loc = state.matchedLocation;

      // Admin route guard: once role is loaded, redirect non-admins immediately.
      // Matches UserModel.isAdmin: role == 'admin' || role == 'moderator'.
      if (loc.startsWith('/admin') && authState.loaded) {
        if (!isAuth) return '/login';
        final r = authState.role;
        if (r != 'admin' && r != 'moderator') return '/home';
      }

      final publicRoutes = [
        '/splash',
        '/onboarding',
        '/login',
        '/create-account',
        '/forgot-password'
      ];
      final isPublic = publicRoutes.any((r) => loc.startsWith(r));

      if (isAuth && isPublic && loc != '/splash') return '/home';
      if (!isAuth && !isPublic) return '/login';
      return null;
    },
    onException: (context, state, router) {
      final uri = state.uri;
      if (uri.scheme == 'granboulva' && uri.host == 'auth-callback') {
        router.go('/login?auth_error=invalid_link');
        return;
      }
      router.go('/login');
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(
        path: '/login',
        builder: (_, s) =>
            LoginScreen(authError: s.uri.queryParameters['auth_error']),
      ),
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
      GoRoute(path: '/saved', builder: (_, __) => const SavedMatchupsScreen()),
      GoRoute(
          path: '/recent-activity',
          builder: (_, __) => const RecentActivityScreen()),
      GoRoute(
          path: '/my-statistics',
          builder: (_, __) => const MyStatisticsScreen()),
      GoRoute(path: '/top-voices', builder: (_, __) => const TopVoicesScreen()),
      GoRoute(
          path: '/subscriptions',
          builder: (_, __) => const SubscriptionsScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(
          path: '/personal-info',
          builder: (_, __) => const PersonalInfoScreen()),
      GoRoute(path: '/security', builder: (_, __) => const SecurityScreen()),
      GoRoute(
          path: '/verification-request',
          builder: (_, __) => const VerificationRequestScreen()),
      GoRoute(
          path: '/notification-settings',
          builder: (_, __) => const NotificationSettingsScreen()),
      GoRoute(path: '/help', builder: (_, __) => const HelpScreen()),
      GoRoute(
          path: '/creator-dashboard',
          builder: (_, __) => const CreatorDashboardScreen()),
      GoRoute(path: '/streak', builder: (_, __) => const StreakRecoveryScreen()),
      GoRoute(path: '/cosmetics', builder: (_, __) => const CosmeticsStoreScreen()),
      GoRoute(path: '/media-feed', builder: (_, __) => const MediaFeedScreen()),

      // ── Battle routes ──────────────────────────────────────────────────────
      // /battle/:id       — smart dispatcher (status + role → correct sub-screen)
      GoRoute(
        path: '/battle/:id',
        builder: (_, s) => BattleScreen(battleId: s.pathParameters['id']!),
      ),
      // Deep-link sub-routes (used by Realtime navigation and notifications)
      GoRoute(
        path: '/battle/:id/incoming',
        builder: (_, s) =>
            BattleIncomingScreen(battleId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/battle/:id/lobby',
        builder: (_, s) =>
            BattleLobbyScreen(battleId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/battle/:id/live',
        builder: (_, s) =>
            BattleLiveScreen(battleId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/battle/:id/result',
        builder: (_, s) =>
            BattleResultScreen(battleId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/battle/:id/replay',
        builder: (_, s) =>
            BattleReplayScreen(battleId: s.pathParameters['id']!),
      ),
      // Challenge entry point: /challenge/:opponentId
      GoRoute(
        path: '/challenge/:opponentId',
        builder: (_, s) => BattleChallengeScreen(
            opponentId: s.pathParameters['opponentId']!),
      ),
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
                activeAsset: 'assets/images/home_filled.png',
                inactiveAsset: 'assets/images/home_unfilled.png',
                label: 'Akèy',
                index: 0,
                current: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                activeAsset: 'assets/images/notification_filled.png',
                inactiveAsset: 'assets/images/notification_unifilled.png',
                label: 'Notifikasyon',
                index: 1,
                current: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                activeAsset: 'assets/images/profile_filled.png',
                inactiveAsset: 'assets/images/profile_unfilled.png',
                label: 'Pwofil',
                index: 2,
                current: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                activeAsset: 'assets/images/menu_filled.png',
                inactiveAsset: 'assets/images/menu_unfilled.png',
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
  final String activeAsset;
  final String inactiveAsset;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.activeAsset,
    required this.inactiveAsset,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    const activeColor = Color(0xFFA855F7);
    const inactiveColor = Color(0xFF8888AA);
    final color = isActive ? activeColor : inactiveColor;
    final asset = isActive ? activeAsset : inactiveAsset;

    return AppPressable(
      onTap: () => onTap(index),
      haptic: isActive ? AppHaptic.selection : AppHaptic.light,
      pressedScale: 0.92,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  asset,
                  width: 29,
                  height: 29,
                  fit: BoxFit.contain,
                  color: color,
                  colorBlendMode: BlendMode.srcIn,
                ),
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
