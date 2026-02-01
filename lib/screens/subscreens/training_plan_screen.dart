// lib/screens/subscreens/training_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hefestocs/constants/colors.dart';
import 'package:hefestocs/providers/client_store.dart';
import 'package:provider/provider.dart';

class TrainingPlanScreen extends StatelessWidget {
  const TrainingPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final clientStore = context.watch<ClientStore>();
    final snapshot = clientStore.snapshot;

    // Loading
    if (clientStore.isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryGold,
          ),
        ),
      );
    }

    // Error
    if (clientStore.error != null || snapshot == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text(
            'Error al cargar plan de entrenamiento',
            style: textTheme.bodyMedium?.copyWith(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Plan de Entrenamiento',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22.w,
              ),
            ),
            SizedBox(height: 16.h),

            // Card 1: Objetivo (solo si existe)
            if (_hasTrainingObjective(snapshot))
              _buildObjectiveCard(context, snapshot),
            if (_hasTrainingObjective(snapshot)) SizedBox(height: 12.h),

            // Card 2: Estructura
            _buildStructureCard(context, snapshot),
            SizedBox(height: 12.h),

            // Card 3: Programa
            _buildProgramCard(context, snapshot),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  /// Verifica si hay objetivo de entrenamiento
  bool _hasTrainingObjective(snapshot) {
    final training = snapshot.rawPayload?['training'];
    if (training is Map) {
      return training['objective'] != null &&
          (training['objective'] as String).trim().isNotEmpty;
    }
    return false;
  }

  /// Card 1: Objetivo de entrenamiento
  Widget _buildObjectiveCard(BuildContext context, snapshot) {
    final textTheme = Theme.of(context).textTheme;
    final training = snapshot.rawPayload?['training'] as Map?;
    final objective = training?['objective'] as String? ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined,
                  size: 18.w, color: AppTheme.primaryGold),
              SizedBox(width: 8.w),
              Text(
                'Objetivo de entrenamiento',
                style: textTheme.titleSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 14.w,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            objective,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 15.w,
            ),
          ),
        ],
      ),
    );
  }

  /// Card 2: Estructura del programa
  Widget _buildStructureCard(BuildContext context, snapshot) {
    final textTheme = Theme.of(context).textTheme;
    final training = snapshot.rawPayload?['training'] as Map?;

    // Extraer datos de estructura
    final frequency = training?['frequency'] as String? ?? 'No especificada';
    final split = training?['split'] as String?;
    final status = training?['status'] as String? ?? 'Pendiente';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estructura del Programa',
            style: textTheme.titleSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 14.w,
            ),
          ),
          SizedBox(height: 16.h),
          // Frecuencia
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 16.w, color: AppTheme.primaryGold),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frecuencia',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 12.w,
                      ),
                    ),
                    Text(
                      frequency,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.w,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Split (si existe)
          if (split != null && split.trim().isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.fitness_center,
                    size: 16.w, color: AppTheme.primaryGold),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Split / Enfoque',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 12.w,
                        ),
                      ),
                      Text(
                        split,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 14.w,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
          ],
          // Estado
          Row(
            children: [
              Icon(Icons.info_outline, size: 16.w, color: AppTheme.primaryGold),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 12.w,
                      ),
                    ),
                    Text(
                      _formatStatus(status),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.w,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Card 3: Detalles del programa
  Widget _buildProgramCard(BuildContext context, snapshot) {
    final textTheme = Theme.of(context).textTheme;
    final training = snapshot.rawPayload?['training'] as Map?;
    final program = training?['program'];

    // Si no hay programa
    if (program == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppTheme.textSecondary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.directions_run_outlined,
              size: 48.w,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            SizedBox(height: 12.h),
            Text(
              'Tu plan de entrenamiento aún no ha sido asignado por tu coach.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 14.w,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              'Cuando lo asigne, verás aquí los detalles.',
              style: textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                fontSize: 12.w,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Si hay programa, mostrar resumen
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline,
                  size: 20.w, color: AppTheme.primaryGold),
              SizedBox(width: 8.w),
              Text(
                'Programa asignado',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.w,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildProgramSummary(context, program),
        ],
      ),
    );
  }

  /// Resumen del programa
  Widget _buildProgramSummary(BuildContext context, dynamic program) {
    final textTheme = Theme.of(context).textTheme;
    final List<String> summaryItems = [];

    if (program is Map) {
      // Tipo de programa
      final type = program['type'] as String?;
      if (type != null && type.trim().isNotEmpty) {
        summaryItems.add('Tipo: $type');
      }

      // Fase actual
      final phase = program['phase'] as String?;
      if (phase != null && phase.trim().isNotEmpty) {
        summaryItems.add('Fase: $phase');
      }

      // Descripción general
      final description = program['description'] as String?;
      if (description != null && description.trim().isNotEmpty) {
        summaryItems.add('Descripción: $description');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summaryItems.isNotEmpty)
          ...summaryItems.map((item) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 16.w, color: AppTheme.primaryGold),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        item,
                        style: textTheme.bodySmall?.copyWith(fontSize: 12.w),
                      ),
                    ),
                  ],
                ),
              ))
        else
          Text(
            'Programa configurado por tu coach',
            style: textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 12.w,
            ),
          ),
      ],
    );
  }

  /// Formatea el estado para mostrar
  String _formatStatus(String status) {
    if (status.toLowerCase() == 'active') {
      return 'Activo';
    }
    return 'Pendiente';
  }

  /// Obtiene color del estado
  Color _getStatusColor(String status) {
    if (status.toLowerCase() == 'active') {
      return Colors.green;
    }
    return Colors.orange;
  }
}
