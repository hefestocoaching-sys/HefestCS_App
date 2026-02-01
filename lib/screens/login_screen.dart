import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hefestocs/constants/colors.dart';
import 'package:hefestocs/screens/main_wrapper.dart';
import 'package:hefestocs/services/invitation_code_service.dart';
import 'package:hefestocs/services/session_service.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _codeController = TextEditingController();
  final InvitationCodeService _invitationService = InvitationCodeService();
  final SessionService _sessionService = SessionService();

  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleAccessCode() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      debugPrint('⚠️ Código vacío');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _invitationService.validateCode(
        invitationCode: code,
      );

      if (result != null) {
        debugPrint('Access OK → ${result.clientId} | ${result.displayName}');

        // Guardar sesión
        await _sessionService.saveSession(
          clientId: result.clientId,
          coachId: result.coachId,
          displayName: result.displayName,
          docPath: result.docPath,
        );

        // Mostrar SnackBar de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bienvenido, ${result.displayName}')),
          );
        }

        // Navegar a MainWrapper
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainWrapper()),
          );
        }
        _codeController.clear();
      } else {
        debugPrint('❌ Código inválido');

        // Mostrar SnackBar de error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Código inválido')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              Center(
                child: Image.asset(
                  'assets/hcs.png',
                  height: 150.h,
                ),
              ),
              const Spacer(flex: 1),
              Text(
                '¡Bienvenido a tu Transformación!',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22.w, // Reducido
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Ingresa para continuar.',
                style:
                    textTheme.titleMedium?.copyWith(fontSize: 15.w), // Reducido
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(hintText: 'Tu código aquí'),
                style: const TextStyle(color: Colors.black),
                enabled: !_isLoading,
                onSubmitted: (_) => _handleAccessCode(),
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleAccessCode,
                child: _isLoading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Acceder'),
              ),
              const Spacer(flex: 2),
              TextButton(
                onPressed: () async {
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'soporte@hefestocs.com',
                    query: 'subject=Problemas con mi código',
                  );
                  await launchUrl(emailLaunchUri);
                },
                child: Text(
                  '¿Problemas con tu código? Contáctanos',
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11.w, // Reducido
                    decoration: TextDecoration.underline,
                    decorationColor: AppTheme.textSecondary,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
