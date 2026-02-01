// lib/screens/subscreens/training_chart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hefestocs/constants/colors.dart';

// REFACTOR: Se elimina el Scaffold y el AppBar
class TrainingChartScreen extends StatelessWidget {
  const TrainingChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Aquí va la Gráfica de Entrenamiento',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 15.w,
            ),
      ),
    );
  }
}
