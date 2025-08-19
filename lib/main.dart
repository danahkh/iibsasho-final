import 'package:flutter/material.dart';
import 'constant/app_color.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/utils/supabase_helper.dart';
import 'views/screens/page_switcher.dart';
import 'views/screens/password_reset_page.dart';
import 'dart:async';

// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Supabase project credentials
const String supabaseUrl = 'https://lvvlhybntvxmohairkpi.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx2dmxoeWJudHZ4bW9oYWlya3BpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNjI1MTAsImV4cCI6MjA2ODgzODUxMH0.z-3Kd-F2uqhMhWV4el5Z8Y_4n_tlTCkQdiOrMkYTjVM';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase with error handling
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  // Initialization complete
  } catch (e) {
  // Suppressed debug print
    // Show error dialog or handle gracefully
  }
  
  runApp(MyApp());
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: AppColor.primary,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColor.background,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  StreamSubscription<AuthState>? _authSub;
  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.passwordRecovery) {
        Future.microtask(() {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PasswordResetPage()),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _checkUserAndDoc(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        if (snapshot.data != null) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              scaffoldBackgroundColor: AppColor.background,
              fontFamily: 'Nunito',
              primaryColor: AppColor.primary,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColor.primary,
                brightness: Brightness.light,
                background: AppColor.background,
                surface: AppColor.cardBackground,
                primary: AppColor.primary,
                secondary: AppColor.accent,
                error: AppColor.error,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: AppColor.primary,
                foregroundColor: AppColor.textLight,
                elevation: 2,
                shadowColor: AppColor.shadowColor,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: AppColor.textLight,
                  elevation: 2,
                  shadowColor: AppColor.shadowColor,
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                fillColor: AppColor.inputBackground,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColor.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColor.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColor.primary, width: 2),
                ),
              ),
            ),
            localizationsDelegates: [
              // AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
              Locale('so'),
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale?.languageCode) {
                  return supportedLocale;
                }
              }
              return supportedLocales.first;
            },
            locale: _locale,
            home: PageSwitcher(),
          );
        } else {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              scaffoldBackgroundColor: AppColor.background,
              fontFamily: 'Nunito',
              primaryColor: AppColor.primary,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColor.primary,
                brightness: Brightness.light,
                background: AppColor.background,
                surface: AppColor.cardBackground,
                primary: AppColor.primary,
                secondary: AppColor.accent,
                error: AppColor.error,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: AppColor.primary,
                foregroundColor: AppColor.textLight,
                elevation: 2,
                shadowColor: AppColor.shadowColor,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: AppColor.textLight,
                  elevation: 2,
                  shadowColor: AppColor.shadowColor,
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                fillColor: AppColor.inputBackground,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColor.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColor.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColor.primary, width: 2),
                ),
              ),
            ),
            localizationsDelegates: [
              // AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
              Locale('so'),
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale?.languageCode) {
                  return supportedLocale;
                }
              }
              return supportedLocales.first;
            },
            locale: _locale,
            home: PageSwitcher(),
          );
        }
      },
    );
  }

  Future<User?> _checkUserAndDoc() async {
    final user = SupabaseHelper.currentUser;
    if (user == null) return null;
    
    try {
      // Check if user profile exists in users table
      final profile = await SupabaseHelper.getCurrentUserProfile();
      if (profile == null) {
        await SupabaseHelper.signOut();
        return null;
      }
      return user;
    } catch (e) {
      // If there's an error accessing the profile, sign out
      await SupabaseHelper.signOut();
      return null;
    }
  }
}
