// lib/screens/charts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hefestocs/constants/colors.dart';
import 'package:hefestocs/providers/charts_navigation_provider.dart';
import 'package:hefestocs/screens/subscreens/measurements_chart_screen.dart';
import 'package:hefestocs/screens/subscreens/training_chart_screen.dart';
import 'package:provider/provider.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final page = context.watch<ChartsNavigationProvider>().currentPage;

    return switch (page) {
      ChartsSubPage.menu => const _ChartsMenu(),
      ChartsSubPage.measurements => const MeasurementsChartScreen(),
      ChartsSubPage.training => const TrainingChartScreen(),
    };
  }
}

class _ChartsMenu extends StatelessWidget {
  const _ChartsMenu();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ChartsNavigationProvider>();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            'El progreso no es lineal',
            style: TextStyle(fontSize: 20.w, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: _ChartButton(
                  title: 'Gráfica de\nmediciones',
                  icon: FontAwesomeIcons.ruler,
                  onTap: () => provider.goTo(ChartsSubPage.measurements),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _ChartButton(
                  title: 'Gráfica de\nentrenamiento',
                  icon: Icons.fitness_center,
                  onTap: () => provider.goTo(ChartsSubPage.training),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartButton extends StatelessWidget {
  const _ChartButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        height: 100.h,
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceTransparent,
          borderRadius: BorderRadius.all(Radius.circular(16.r)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primaryGold, size: 30.w),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(fontSize: 13.w, color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
