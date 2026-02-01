import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hefestocs/constants/colors.dart';
import 'package:hefestocs/providers/client_store.dart';
import 'package:hefestocs/providers/session_provider.dart';
import 'package:hefestocs/screens/biochem_screen.dart';
import 'package:hefestocs/screens/charts_screen.dart';
import 'package:hefestocs/screens/home_screen.dart';
import 'package:hefestocs/services/session_service.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hefestocs/navigation_provider.dart';
import 'package:hefestocs/providers/charts_navigation_provider.dart';
import 'package:hefestocs/providers/nutrition_navigation_provider.dart';
import 'package:hefestocs/providers/training_navigation_provider.dart';
import 'package:hefestocs/screens/login_screen.dart';
import 'package:hefestocs/screens/training_screen.dart';
import 'package:hefestocs/screens/nutrition_screen.dart';
import 'package:hefestocs/config/app_config.dart';

class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final trainingNav = context.watch<TrainingNavigationProvider>();
    final nutritionNav = context.watch<NutritionNavigationProvider>();
    final chartsNav = context.watch<ChartsNavigationProvider>();
    final selectedIndex = navProvider.selectedIndex;

    return PopScope(
      canPop: false,
      // REFACTOR: Se usa onPopInvokedWithResult para eliminar la advertencia
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        if (selectedIndex == 1 &&
            nutritionNav.currentPage != NutritionSubPage.menu) {
          nutritionNav.backToMenu();
          return;
        }
        if (selectedIndex == 2 &&
            trainingNav.currentPage != TrainingSubPage.menu) {
          trainingNav.backToMenu();
          return;
        }
        if (selectedIndex == 3 && chartsNav.currentPage != ChartsSubPage.menu) {
          chartsNav.backToMenu();
          return;
        }
        if (selectedIndex != 0) {
          navProvider.setIndex(0);
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/fondo_1.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: IndexedStack(
            index: selectedIndex,
            children: const [
              HomePageContent(),
              NutritionScreen(),
              TrainingScreen(),
              ChartsScreen(),
              BiochemScreen(),
            ],
          ),
        ),
        bottomNavigationBar: const _BottomNavBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final navProvider = context.read<NavigationProvider>();
    final trainingNav = context.watch<TrainingNavigationProvider>();
    final nutritionNav = context.watch<NutritionNavigationProvider>();
    final chartsNav = context.watch<ChartsNavigationProvider>();
    final selectedIndex = navProvider.selectedIndex;

    bool isInSubPage = false;
    String subPageTitle = '';
    VoidCallback? onBack;

    if (selectedIndex == 1 &&
        nutritionNav.currentPage != NutritionSubPage.menu) {
      isInSubPage = true;
      subPageTitle = _getSubPageTitle(nutritionNav.currentPage);
      onBack = () => nutritionNav.backToMenu();
    } else if (selectedIndex == 2 &&
        trainingNav.currentPage != TrainingSubPage.menu) {
      isInSubPage = true;
      subPageTitle = _getSubPageTitle(trainingNav.currentPage);
      onBack = () => trainingNav.backToMenu();
    } else if (selectedIndex == 3 &&
        chartsNav.currentPage != ChartsSubPage.menu) {
      isInSubPage = true;
      subPageTitle = _getSubPageTitle(chartsNav.currentPage);
      onBack = () => chartsNav.backToMenu();
    }

    return AppBar(
      centerTitle: isInSubPage,
      title: isInSubPage
          ? Text(subPageTitle,
              style: TextStyle(fontFamily: 'Roboto', fontSize: 20.w))
          : const Text(AppBrand.name, style: TextStyle(fontFamily: 'FINALOLD')),
      leading: isInSubPage
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios), onPressed: onBack)
          : null,
      actions: isInSubPage
          ? [const SizedBox(width: 56)]
          : [
              // Botón de logout
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  // Limpiar sesión en SharedPreferences
                  final sessionService = SessionService();
                  await sessionService.clearSession();

                  // Limpiar sesión en Provider
                  if (context.mounted) {
                    context.read<SessionProvider>().clearSession();
                    context.read<ClientStore>().clear();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                      (r) => false,
                    );
                  }
                },
              ),
            ],
    );
  }

  String _getSubPageTitle(dynamic page) {
    switch (page) {
      case TrainingSubPage.photos:
        return 'Progreso Visual';
      case TrainingSubPage.plan:
        return 'Plan de Hoy';
      case TrainingSubPage.log:
        return 'Bitácora';
      case NutritionSubPage.plan:
        return 'Plan Alimenticio';
      case NutritionSubPage.equivalentes:
        return 'Equivalentes';
      case NutritionSubPage.mediciones:
        return 'Mediciones';
      case ChartsSubPage.measurements:
        return 'Gráfica de Mediciones';
      case ChartsSubPage.training:
        return 'Gráfica de Entrenamiento';
      default:
        return '';
    }
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final trainingNav = context.read<TrainingNavigationProvider>();
    final nutritionNav = context.read<NutritionNavigationProvider>();
    final chartsNav = context.read<ChartsNavigationProvider>();
    final selectedIndex = navProvider.selectedIndex;

    void onNavItemTap(int index) {
      if (selectedIndex != index) {
        navProvider.setIndex(index);
      } else {
        if (index == 1) nutritionNav.backToMenu();
        if (index == 2) trainingNav.backToMenu();
        if (index == 3) chartsNav.backToMenu();
      }
    }

    return Container(
      color: AppTheme.navBar,
      child: SafeArea(
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _BottomNavItem(
            index: 0,
            icon: Icons.home,
            unselectedIcon: Icons.home_outlined,
            isSelected: selectedIndex == 0,
            onTap: () => onNavItemTap(0)),
        _BottomNavItem(
            index: 1,
            icon: Icons.restaurant_menu,
            unselectedIcon: Icons.restaurant_menu_outlined,
            isSelected: selectedIndex == 1,
            onTap: () => onNavItemTap(1)),
        _BottomNavItem(
            index: 2,
            icon: Icons.fitness_center,
            unselectedIcon: Icons.fitness_center_outlined,
            isSelected: selectedIndex == 2,
            onTap: () => onNavItemTap(2)),
        _BottomNavItem(
            index: 3,
            icon: FontAwesomeIcons.solidChartBar,
            unselectedIcon: FontAwesomeIcons.chartBar,
            isSelected: selectedIndex == 3,
            onTap: () => onNavItemTap(3),
            isFaIcon: true),
        _BottomNavItem(
            index: 4,
            icon: FontAwesomeIcons.flaskVial,
            unselectedIcon: FontAwesomeIcons.flask,
            isSelected: selectedIndex == 4,
            onTap: () => onNavItemTap(4),
            isFaIcon: true),
      ])),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.index,
    required this.icon,
    required this.unselectedIcon,
    required this.isSelected,
    required this.onTap,
    this.isFaIcon = false,
  });

  final int index;
  final IconData icon, unselectedIcon;
  final bool isSelected, isFaIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = this.isSelected;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 50.0,
          child: Center(
            child: isFaIcon
                ? FaIcon(isSelected ? icon : unselectedIcon,
                    color: isSelected
                        ? AppTheme.primaryGold
                        : AppTheme.unselectedItemColor,
                    size: 24.0)
                : Icon(isSelected ? icon : unselectedIcon,
                    color: isSelected
                        ? AppTheme.primaryGold
                        : AppTheme.unselectedItemColor,
                    size: 30.0),
          ),
        ),
      ),
    );
  }
}
