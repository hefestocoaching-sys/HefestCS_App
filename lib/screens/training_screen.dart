// lib/screens/training_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hefestocs/providers/training_navigation_provider.dart';
import 'package:hefestocs/screens/menu_screen_template.dart';
import 'package:hefestocs/screens/subscreens/logbook_screen.dart';
import 'package:hefestocs/screens/subscreens/training_plan_screen.dart';
import 'package:provider/provider.dart';
// REFACTOR: Se actualiza la ruta de importación a la nueva arquitectura de 'features'
import 'package:hefestocs/features/progress_photos/progress_photos_screen.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final page = context.watch<TrainingNavigationProvider>().currentPage;

    return switch (page) {
      TrainingSubPage.menu => const _TrainingMenu(),
      TrainingSubPage.photos => const ProgressPhotosScreen(),
      TrainingSubPage.plan => const TrainingPlanScreen(),
      TrainingSubPage.log => const LogbookScreen(),
    };
  }
}

class _TrainingMenu extends StatelessWidget {
  const _TrainingMenu();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TrainingNavigationProvider>();
    return MenuScreenTemplate(
      title: '¡Tu mejor versión te espera!',
      featuredCardTitle: 'Ver el Plan de Hoy',
      featuredCardSubtitle: 'Revisa tu rutina asignada.',
      featuredCardIcon: Icons.calendar_today_outlined,
      featuredCardOnTap: () => provider.goTo(TrainingSubPage.plan),
      horizontalMenuItems: [
        HorizontalMenuItem(
          icon: FontAwesomeIcons.book,
          title: 'Bitácora',
          onTap: () => provider.goTo(TrainingSubPage.log),
        ),
        HorizontalMenuItem(
          icon: Icons.camera_alt_outlined,
          title: 'Progreso Visual',
          onTap: () => provider.goTo(TrainingSubPage.photos),
        ),
      ],
    );
  }
}
