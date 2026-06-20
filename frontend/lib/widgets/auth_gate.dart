import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/encounter_service.dart';
import '../theme/app_theme.dart';
import '../screens/battle_timeline_screen.dart';
import '../screens/login_screen.dart';

/// Listens to Firebase auth state and routes to either the login screen
/// or the main encounter screen.
class AuthGate extends StatelessWidget {
  final String encounterId;
  final AuthService authService;

  const AuthGate({
    super.key,
    required this.encounterId,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            ),
          );
        }

        if (snapshot.data != null) {
          return BattleTimelineScreen(
            encounterId: encounterId,
            service: EncounterService(),
          );
        }

        return LoginScreen(authService: authService);
      },
    );
  }
}
