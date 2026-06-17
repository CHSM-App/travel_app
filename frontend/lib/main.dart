import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/bottom_navigation_bar.dart';
import 'package:travel_agency_app/Screens/login.dart';
import 'package:travel_agency_app/core/network/token_provider.dart';
import 'package:travel_agency_app/core/notifications/notification_store.dart';
import 'package:travel_agency_app/core/notifications/push_service.dart';
import 'package:travel_agency_app/core/notifications/trip_alarm_service.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/presentation/providers/repository_provider.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    // App must still run if Firebase isn't configured yet (e.g. missing
    // google-services.json on a dev machine).
    debugPrint('Firebase init failed: $e');
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Vego',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.surface,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brandPrimary,
          primary: AppColors.brandPrimary,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.brandHeader,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      home: const SplashScreen(),
    );
  }
}


class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    await ref.read(tokenProvider.notifier).loadTokens();
    await ref.read(loginViewModelProvider.notifier).loadFromStorage();

    try {
      await NotificationStore.instance.load();
      await PushService.init(ref.read(apiServiceProvider));
      // Load persisted trip reminders so the bell icon shows the right state.
      await TripAlarmService.ensureReady();
    } catch (e) {
      debugPrint('PushService init failed: $e');
    }

    final tokenState = ref.read(tokenProvider);

    if (!mounted) return;

    if (tokenState.isLoggedIn) {
      PushService.registerToken();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainBottomNav()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/branding/vego_logo.png',
              width: 160,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const Text(
              'Vego',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: AppColors.brandHeader,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class HexColor extends Color {
  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));

  static int _getColorFromHex(String hexColor) {
    var hex = hexColor.toUpperCase().replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return int.parse(hex, radix: 16);
  }
}
