import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/encounter_service.dart';
import 'theme/app_theme.dart';
import 'widgets/auth_gate.dart';

/// Entry point. Initialise Firebase then run the app.
///
/// Pass the ENCOUNTER_ID via --dart-define at build/run time:
///   flutter run --dart-define=ENCOUNTER_ID=your_encounter_id
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const StrixhavenApp());
}

class StrixhavenApp extends StatelessWidget {
  const StrixhavenApp({super.key});

  static const String _encounterId =
      String.fromEnvironment('ENCOUNTER_ID', defaultValue: 'demo_encounter');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strixhaven — Encounter Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme.copyWith(
        textTheme: GoogleFonts.interTextTheme(AppTheme.theme.textTheme),
      ),
      home: AuthGate(
        encounterId: _encounterId,
        authService: AuthService(),
        encounterService: EncounterService(),
      ),
    );
  }
}
