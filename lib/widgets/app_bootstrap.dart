import 'package:flutter/material.dart';
import 'package:hefestocs/screens/login_screen.dart';
import 'package:hefestocs/screens/main_wrapper.dart';
import 'package:hefestocs/services/session_service.dart';

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: SessionService().hasSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Mostrar splash mientras verifica sesión
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final hasSession = snapshot.data ?? false;

        if (hasSession) {
          debugPrint('📱 Sesión detectada → navegando a MainWrapper');
          return const MainWrapper();
        } else {
          debugPrint('🔐 Sin sesión → navegando a Login');
          return const LoginScreen();
        }
      },
    );
  }
}
