import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_router.dart';
import 'config/app_colors.dart';
import 'config/app_theme.dart';
import 'config/supabase_config.dart';
import 'widgets/badges/badge_unlock_overlay.dart';

void main() {
  bootstrapGranBoulvaApp();
}

Future<void> bootstrapGranBoulvaApp({bool resetAuthSession = false}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  // Load .env
  await dotenv.load(fileName: '.env');

  // Init Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  if (resetAuthSession) {
    await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
  }

  // Init Stripe
  Stripe.publishableKey = StripeConfig.publishableKey;
  await Stripe.instance.applySettings();

  runApp(const GranBoulvaApp());
}

class GranBoulvaApp extends StatefulWidget {
  const GranBoulvaApp({super.key});

  @override
  State<GranBoulvaApp> createState() => _GranBoulvaAppState();
}

class _GranBoulvaAppState extends State<GranBoulvaApp> {
  late final _router = createRouter();
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((authState) {
      final event = authState.event;
      if (event == AuthChangeEvent.signedOut) {
        _router.go('/login');
        return;
      }

      final session = authState.session;
      if (session == null) return;

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        _router.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gran Boulva',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
      builder: (context, child) {
        return BadgeUnlockOverlayHost(
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.noScaling),
            child: Stack(
              children: [
                const Positioned.fill(child: ColoredBox(color: AppColors.bg0)),
                child!,
              ],
            ),
          ),
        );
      },
    );
  }
}
