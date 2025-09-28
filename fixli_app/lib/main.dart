// lib/main.dart

import 'package:fixli_app/presentation/providers/auth_provider.dart';
import 'package:fixli_app/presentation/providers/onboarding_provider.dart'; // 🟢 Ny import
import 'package:fixli_app/presentation/screens/home_screen.dart';
import 'package:fixli_app/presentation/screens/onboarding_screen.dart'; // 🟢 Ny import
import 'package:fixli_app/presentation/screens/welcome_screen.dart';
import 'package:fixli_app/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  timeago.setLocaleMessages('sv', timeago.SvMessages());
  setupLocator();
  runApp(const ProviderScope(child: FixliApp()));
}

class FixliApp extends ConsumerWidget {
  const FixliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isAuthenticated == false && next.isAuthenticated == true) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
        );
      }
      if (previous?.isAuthenticated == true && next.isAuthenticated == false) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
        );
      }
    });

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Fixli',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal,
          secondary: Colors.amber,
          background: const Color(0xFFF5F5F5),
        ),
        textTheme: GoogleFonts.nunitoSansTextTheme(Theme.of(context).textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // 🟢 Använder den nya AppEntryPoint som startpunkt
      home: const AppEntryPoint(),

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [ Locale('sv', 'SE'), Locale('en', 'US') ],
      locale: const Locale('sv', 'SE'),
    );
  }
}

// 🟢 Ny widget som bestämmer vilken allra första skärm som ska visas
class AppEntryPoint extends ConsumerWidget {
  const AppEntryPoint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingNotifierProvider);

    return onboardingState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => const Scaffold(body: Center(child: Text('Kunde inte ladda app-inställningar'))),
      data: (hasSeenOnboarding) {
        if (hasSeenOnboarding) {
          // Om de har sett guiden, kör den vanliga inloggningslogiken
          return const AuthNavigator();
        } else {
          // Annars, visa guiden
          return const OnboardingScreen();
        }
      },
    );
  }
}

// Din befintliga widget för att hantera inloggningsstatus
class AuthNavigator extends ConsumerWidget {
  const AuthNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (authState.isAuthenticated) {
      return const HomeScreen();
    } else {
      return const WelcomeScreen();
    }
  }
}