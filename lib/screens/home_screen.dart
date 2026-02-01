import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hefestocs/constants/colors.dart';
import 'package:hefestocs/providers/client_store.dart';
import 'package:hefestocs/providers/session_provider.dart';
import 'package:hefestocs/screens/login_screen.dart';
import 'package:hefestocs/services/session_service.dart';
import 'package:hefestocs/widgets/user_info_card.dart';
import 'package:provider/provider.dart';

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  static const List<String> _carouselImages = [
    'assets/images/1.png',
    'assets/images/2.png',
    'assets/images/3.png',
    'assets/images/4.png',
    'assets/images/5.png',
    'assets/images/6.png',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final clientStore = context.watch<ClientStore>();

    // Estado de carga
    if (clientStore.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Error
    if (clientStore.error != null) {
      // Detectar si es error de sesión incompatible
      final isSessionError = clientStore.error!.contains('Sesión incompatible');

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: () => clientStore.refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSessionError ? Icons.logout : Icons.error_outline,
                      size: 48.w,
                      color: isSessionError ? Colors.orange : Colors.red,
                    ),
                    SizedBox(height: 16.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.w),
                      child: Text(
                        clientStore.error!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: isSessionError ? Colors.orange : Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    if (isSessionError)
                      ElevatedButton.icon(
                        onPressed: () async {
                          // Limpiar sesión y volver a login
                          await context.read<SessionService>().clearSession();
                          context.read<SessionProvider>().clearSession();
                          context.read<ClientStore>().clear();

                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Cerrar sesión y volver a iniciar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => clientStore.refresh(),
                        child: const Text('Reintentar'),
                      ),
                    if (!isSessionError) ...[
                      SizedBox(height: 8.h),
                      Text(
                        'O desliza hacia abajo para recargar',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Sin datos
    if (clientStore.client == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text('Sin datos del cliente'),
        ),
      );
    }

    // Datos del cliente
    final client = clientStore.client!;
    final snapshot = clientStore.snapshot!;

    // Calcular progreso de macros (ejemplo simplificado)
    final totalMacros = client.proteinG + client.fatG + client.carbG;
    final kcalProgress =
        totalMacros > 0 ? 0.75 : 0.0; // TODO: Calcular progreso real

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => context.read<ClientStore>().refresh(),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/fondo_1.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    '¿Listo para progresar hoy?',
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.w,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: UserInfoCard(
                    userName: client.fullName,
                    planType: snapshot.deficitOrSurplusText,
                    kcalProgress: kcalProgress,
                    fatPercentage: snapshot.bodyFatPercentage,
                    musclePercentage: snapshot.muscleMassPercentage,
                    kcalValue:
                        '${(kcalProgress * client.kcalTarget).toInt()}/${client.kcalTarget}',
                  ),
                ),
                SizedBox(height: 20.h),
                CarouselSlider.builder(
                  itemCount: _carouselImages.length,
                  itemBuilder: (context, index, realIndex) =>
                      _CarouselItem(imageUrl: _carouselImages[index]),
                  options: CarouselOptions(
                    height: 380.h,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    aspectRatio: 16 / 9,
                    viewportFraction: 0.8,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// El widget _CarouselItem se mantiene privado porque solo se usa aquí.
class _CarouselItem extends StatelessWidget {
  const _CarouselItem({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        image: DecorationImage(image: AssetImage(imageUrl), fit: BoxFit.cover),
        boxShadow: AppTheme.cardShadow,
      ),
    );
  }
}
