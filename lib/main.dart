import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'config/app_theme.dart';
import 'providers/providers.dart';
import 'screens/auth/login_screen.dart';
import 'screens/patient/patient_home_screen.dart';
import 'screens/clinician/clinician_dashboard_screen.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyC2XZ0nMI8WMjQYXInziAeIl04wt9e5aqU',
      appId: '1:622507436148:web:a0e39c83a0701e6d3fc921',
      messagingSenderId: '622507436148',
      projectId: 'crohns-635ee',
      storageBucket: 'crohns-635ee.firebasestorage.app',
      authDomain: 'crohns-635ee.firebaseapp.com',
      measurementId: 'G-N6D869DD9D',
    ),
  );
  
  runApp(const CrohnsExperienceApp());
}

class CrohnsExperienceApp extends StatelessWidget {
  const CrohnsExperienceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SymptomProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => DietProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: "Crohn's Experience",
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
            ],
            locale: localeProvider.locale,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        if (authProvider.user?.role == UserRole.patient) {
          return const PatientHomeScreen();
        } else if (authProvider.user?.role == UserRole.clinician ||
            authProvider.user?.role == UserRole.researcher) {
          return const ClinicianDashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
