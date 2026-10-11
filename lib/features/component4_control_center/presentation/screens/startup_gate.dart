import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/services/auth_firebase_service.dart';
import '../../data/services/session_service.dart';
import '../controllers/responder_controller.dart';
import 'responder_login_screen.dart';
import 'role_router.dart';

/// First screen of the app. If someone chose "Remember credentials" and did
/// not log out, they are taken straight to their dashboard; otherwise the
/// login page is shown.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late final Future<Widget> _target = _resolve();

  Future<Widget> _resolve() async {
    final email = await SessionService.read();
    if (email != null) {
      try {
        final user = await AuthFirebaseService()
            .loadUserByEmail(email)
            .timeout(const Duration(seconds: 8));
        ResponderController().setCurrentUser(user);
        return dashboardForRole(user.role);
      } on TimeoutException {
        // Slow / no connection: keep the saved login for the next start and
        // show the login page this time.
      } catch (_) {
        // Account removed or disabled, or no data: fall back to the login page.
        await SessionService.clear();
      }
    }
    return const ResponderLoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _target,
      builder: (context, snap) {
        if (snap.hasData) return snap.data!;
        return const Scaffold(
          backgroundColor: Color(0xFF070B14),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFFFF5252)),
          ),
        );
      },
    );
  }
}
