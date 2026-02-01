// lib/screens/nutrition_screen.dart
import 'package:flutter/material.dart';
import 'package:hefestocs/providers/nutrition_navigation_provider.dart';
import 'package:hefestocs/screens/menu_screen_template.dart';
import 'package:hefestocs/screens/subscreens/equivalents_screen.dart';
import 'package:hefestocs/screens/subscreens/measurements_screen.dart';
import 'package:hefestocs/screens/subscreens/nutrition_plan_screen.dart';
import 'package:provider/provider.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final page = context.watch<NutritionNavigationProvider>().currentPage;

    // El switch ahora devuelve los widgets de las sub-pantallas directamente
    return switch (page) {
      NutritionSubPage.menu => const _NutritionMenu(),
      NutritionSubPage.plan => const NutritionPlanScreen(),
      NutritionSubPage.equivalentes => const EquivalentsScreen(),
      NutritionSubPage.mediciones => const MeasurementsScreen(),
    };
  }
}

class _NutritionMenu extends StatelessWidget {
  const _NutritionMenu();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NutritionNavigationProvider>();
    return MenuScreenTemplate(
      title: 'Nutre. Entrena. Evoluciona.',
      featuredCardTitle: 'Ver Plan Alimenticio',
      featuredCardSubtitle: 'Consulta tus comidas y porciones.',
      featuredCardIcon: Icons.restaurant_menu,
      featuredCardOnTap: () => provider.goTo(NutritionSubPage.plan),
      horizontalMenuItems: [
        HorizontalMenuItem(
          icon: Icons.swap_horiz,
          title: 'Equivalentes',
          onTap: () => provider.goTo(NutritionSubPage.equivalentes),
        ),
        HorizontalMenuItem(
          icon: Icons.straighten,
          title: 'Mediciones',
          onTap: () => provider.goTo(NutritionSubPage.mediciones),
        ),
      ],
    );
  }
}
