import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/auth_service.dart';
import 'services/local_storage.dart';
import 'services/notification_service.dart';
import 'services/gemini_service.dart';
import 'services/settings_service.dart';
import 'services/localization_service.dart';
import 'ui/splash_screen.dart';
import 'ui/auth/login_screen.dart';
import 'ui/auth/register_screen.dart';
import 'ui/auth/forgot_screen.dart';
import 'ui/kyc/health_questionnaire.dart';
import 'ui/tabs/home_screen.dart';
import 'ui/tabs/daily_checkup_screen.dart';
import 'ui/tabs/med_bot_screen.dart';
import 'ui/tabs/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize only critical services synchronously
  await LocalStorage.instance.init();
  
  // Initialize settings service
  final settingsService = SettingsService();
  await settingsService.init();
  
  // Initialize notification service in background (not blocking)
  NotificationService.instance.init().catchError((e) {
    print('Notification service init failed: $e');
  });
  
  runApp(MaitreeApp(settingsService: settingsService));
}

class MaitreeApp extends StatelessWidget {
  final SettingsService settingsService;
  
  const MaitreeApp({super.key, required this.settingsService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => GeminiService()),
        ChangeNotifierProvider.value(value: settingsService),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settings, _) => MaterialApp(
          title: 'Maitree',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          locale: LocalizationService.currentLocale,
          supportedLocales: LocalizationService.supportedLocales.values,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D6B)),
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(),
            scaffoldBackgroundColor: const Color(0xFFF5FAF8),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4CAF50),
              brightness: Brightness.dark,
            ).copyWith(
              surface: const Color(0xFF121212),
              onSurface: const Color(0xFFE1E1E1),
              primary: const Color(0xFF66BB6A),
              onPrimary: const Color(0xFF000000),
              secondary: const Color(0xFF81C784),
              onSecondary: const Color(0xFF000000),
              tertiary: const Color(0xFF4DB6AC),
              error: const Color(0xFFCF6679),
              onError: const Color(0xFF000000),
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Color(0xFFE1E1E1),
              elevation: 0,
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: const Color(0xFF1E1E1E),
              indicatorColor: const Color(0xFF66BB6A).withValues(alpha: 0.3),
              labelTextStyle: WidgetStatePropertyAll<TextStyle>(
                const TextStyle(color: Color(0xFFE1E1E1), fontSize: 12),
              ),
            ),
            cardTheme: const CardThemeData(
              color: Color(0xFF1E1E1E),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66BB6A),
                foregroundColor: const Color(0xFF000000),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF444444)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF444444)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF66BB6A)),
              ),
            ),
            snackBarTheme: const SnackBarThemeData(
              backgroundColor: Color(0xFF333333),
              contentTextStyle: TextStyle(color: Color(0xFFE1E1E1)),
            ),
            textTheme: GoogleFonts.poppinsTextTheme(
              ThemeData.dark().textTheme,
            ).apply(
              bodyColor: const Color(0xFFE1E1E1),
              displayColor: const Color(0xFFE1E1E1),
            ),
          ),
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/forgot': (_) => const ForgotPasswordScreen(),
          '/kyc': (_) => const HealthQuestionnaire(),
          },
        ),
      ),
    );
  }
}


class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> with TickerProviderStateMixin {
  int _index = 0;
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final _pages = const [
    HomeScreen(),
    DailyCheckupScreen(),
    MedBotScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _animateToPage(int index) {
    _fadeController.reset();
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _index = index),
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          elevation: 0,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined), 
              selectedIcon: Icon(Icons.home, color: Theme.of(context).colorScheme.primary), 
              label: LocalizationService.t('home')
            ),
            NavigationDestination(
              icon: const Icon(Icons.health_and_safety_outlined), 
              selectedIcon: Icon(Icons.health_and_safety, color: Theme.of(context).colorScheme.primary), 
              label: LocalizationService.t('daily')
            ),
            NavigationDestination(
              icon: const Icon(Icons.smart_toy_outlined), 
              selectedIcon: Icon(Icons.smart_toy, color: Theme.of(context).colorScheme.primary), 
              label: LocalizationService.t('med_bot')
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline), 
              selectedIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary), 
              label: LocalizationService.t('profile')
            ),
          ],
          onDestinationSelected: _animateToPage,
        ),
      ),
    );
  }
}
