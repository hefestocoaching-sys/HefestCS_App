// lib/screens/subscreens/nutrition_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hefestocs/constants/colors.dart';
import 'package:hefestocs/providers/client_store.dart';
import 'package:hefestocs/services/client_data_service.dart';
import 'package:provider/provider.dart';

class NutritionPlanScreen extends StatelessWidget {
  const NutritionPlanScreen({super.key});

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
            'Error al cargar datos nutricionales',
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
              'Plan Nutricional',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22.w,
              ),
            ),
            SizedBox(height: 16.h),

            // Card 1: Energía
            _buildEnergyCard(context, snapshot),
            SizedBox(height: 12.h),

            // Card 2: Macros (solo si existen)
            if (snapshot.proteinG > 0 ||
                snapshot.carbG > 0 ||
                snapshot.fatG > 0)
              _buildMacrosCard(context, snapshot),
            if (snapshot.proteinG > 0 ||
                snapshot.carbG > 0 ||
                snapshot.fatG > 0)
              SizedBox(height: 12.h),

            // Card 3: Objetivo (solo si existe)
            if (snapshot.goalText != 'Sin objetivo definido')
              _buildGoalCard(context, snapshot),
            if (snapshot.goalText != 'Sin objetivo definido')
              SizedBox(height: 20.h),

            // Sección Plan Alimenticio
            Text(
              'Plan Alimenticio',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18.w,
              ),
            ),
            SizedBox(height: 12.h),

            _buildPlanSection(context, snapshot),
            SizedBox(height: 20.h),

            // Sección Estado corporal
            if (snapshot.latestAnthropometry != null) ...[
              Text(
                'Estado Corporal Actual',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.w,
                ),
              ),
              SizedBox(height: 12.h),

              // Card: Última medición
              _buildLatestMeasurementCard(context, snapshot),
              SizedBox(height: 12.h),

              // Card: Medidas corporales (si existen)
              if (_hasBodyMeasurements(snapshot))
                _buildBodyMeasurementsCard(context, snapshot),
              if (_hasBodyMeasurements(snapshot)) SizedBox(height: 12.h),

              // Card: Interpretación
              _buildInterpretationCard(context, snapshot),
              SizedBox(height: 20.h),
            ],
          ],
        ),
      ),
    );
  }

  /// Card 1: Energía diaria - Kcal objetivo + estado
  Widget _buildEnergyCard(BuildContext context, snapshot) {
    final textTheme = Theme.of(context).textTheme;

    final planContainer = Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Energía diaria',
                style: textTheme.titleSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 14.w,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getBadgeColor(snapshot.deficitOrSurplusText),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  snapshot.deficitOrSurplusText,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.w,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(Icons.local_fire_department,
                  size: 24.w, color: Colors.orange),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${snapshot.kcalTarget}',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 28.w,
                    ),
                  ),
                  Text(
                    'kcal/día',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 12.w,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    return planContainer;
  }

  /// Card 2: Macronutrientes (P/C/G)
  Widget _buildMacrosCard(BuildContext context, snapshot) {
    final textTheme = Theme.of(context).textTheme;

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
            'Distribución Macronutrientes',
            style: textTheme.titleSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 14.w,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroColumn(
                context,
                'Proteína',
                '${snapshot.proteinG}g',
                AppTheme.primaryGold,
              ),
              _buildMacroColumn(
                context,
                'Carbohidratos',
                '${snapshot.carbG}g',
                Colors.orange,
              ),
              _buildMacroColumn(
                context,
                'Grasas',
                '${snapshot.fatG}g',
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper para columna de macro
  Widget _buildMacroColumn(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          value,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 22.w,
            color: color,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 11.w,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Card 3: Objetivo personal
  Widget _buildGoalCard(BuildContext context, snapshot) {
    final textTheme = Theme.of(context).textTheme;

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
                'Tu objetivo',
                style: textTheme.titleSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 14.w,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            snapshot.goalText,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 15.w,
            ),
          ),
        ],
      ),
    );
  }

  /// Sección Plan Alimenticio
  Widget _buildPlanSection(BuildContext context, snapshot) {
    final textTheme = Theme.of(context).textTheme;

    // Buscar plan en rawPayload
    final mealPlan = snapshot.rawPayload?['mealPlan'];
    final nutritionPlan = snapshot.rawPayload?['nutritionPlan'];
    final planData = mealPlan ?? nutritionPlan;

    // Si no hay plan
    if (planData == null) {
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
              Icons.restaurant_menu_outlined,
              size: 48.w,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            SizedBox(height: 12.h),
            Text(
              'Tu plan alimenticio aún no ha sido asignado por tu coach.',
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

    // Si hay plan, mostrar resumen (envolvemos en GestureDetector sin alterar visual)
    final container = Container(
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
                'Plan asignado',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.w,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildPlanSummary(context, planData),
        ],
      ),
    );

    return GestureDetector(
      onLongPress: () async {
        final mealKeys = _extractMealKeys(planData);
        if (mealKeys.isEmpty) return;
        await _showAdherenceSelector(context, mealKeys);
      },
      child: container,
    );
  }

  /// Resumen del plan (número de comidas, distribución general)
  Widget _buildPlanSummary(BuildContext context, dynamic planData) {
    final textTheme = Theme.of(context).textTheme;
    int mealCount = 0;
    List<String> summaryItems = [];

    if (planData is Map) {
      // Contar comidas principales
      final mealKeys = [
        'breakfast',
        'lunch',
        'snack',
        'dinner',
        'desayuno',
        'almuerzo',
        'merienda',
        'cena'
      ];
      for (var key in planData.keys) {
        if (mealKeys.any((mk) => key.toLowerCase().contains(mk))) {
          mealCount++;
        }
      }

      // Extraer resumen general
      if (planData['summary'] != null) {
        summaryItems.add(planData['summary'].toString());
      }
      if (planData['distribution'] != null) {
        summaryItems.add('Distribución: ${planData['distribution']}');
      }
    } else if (planData is List && planData.isNotEmpty) {
      mealCount = planData.length;
      if (planData.first is Map && planData.first['name'] != null) {
        summaryItems.add('${planData.length} comidas configuradas');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mealCount > 0) ...[
          Row(
            children: [
              Icon(Icons.restaurant, size: 16.w, color: AppTheme.primaryGold),
              SizedBox(width: 8.w),
              Text(
                '$mealCount comidas diarias',
                style: textTheme.bodyMedium?.copyWith(fontSize: 13.w),
              ),
            ],
          ),
          SizedBox(height: 8.h),
        ],
        if (summaryItems.isNotEmpty)
          ...summaryItems.map((item) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 16.w, color: AppTheme.primaryGold),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        item,
                        style: textTheme.bodySmall?.copyWith(fontSize: 12.w),
                      ),
                    ),
                  ],
                ),
              )),
        if (mealCount == 0 && summaryItems.isEmpty)
          Text(
            'Plan configurado por tu coach',
            style: textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 12.w,
            ),
          ),
      ],
    );
  }

  /// Determina color del badge según estado
  Color _getBadgeColor(String status) {
    if (status.contains('Déficit')) return Colors.red;
    if (status.contains('Superávit')) return Colors.green;
    return Colors.blue;
  }

  /// Verifica si hay medidas corporales
  bool _hasBodyMeasurements(snapshot) {
    final latest = snapshot.latestAnthropometry;
    if (latest == null) return false;
    return latest['waist'] != null ||
        latest['hip'] != null ||
        latest['arm'] != null ||
        latest['thigh'] != null;
  }

  /// Card: Última medición
  Widget _buildLatestMeasurementCard(BuildContext context, snapshot) {
    final textTheme = Theme.of(context).textTheme;
    final latest = snapshot.latestAnthropometry;
    if (latest == null) return SizedBox.shrink();

    final weight = (latest['weight'] as num?)?.toDouble() ?? 0.0;
    final bodyFat = latest['bodyFatPercentage'] as dynamic;
    final muscleMass = latest['muscleMassPercentage'] as dynamic;
    final dateStr = latest['date'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;

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
              Icon(Icons.straighten, size: 18.w, color: AppTheme.primaryGold),
              SizedBox(width: 8.w),
              Text(
                'Última Medición',
                style: textTheme.titleSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 14.w,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Fecha
          if (date != null)
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14.w, color: AppTheme.primaryGold),
                SizedBox(width: 6.w),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 12.w,
                  ),
                ),
              ],
            ),
          if (date != null) SizedBox(height: 8.h),
          // Peso
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Peso',
                style: textTheme.bodyMedium?.copyWith(fontSize: 13.w),
              ),
              Text(
                '${weight.toStringAsFixed(1)} kg',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 13.w,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // % Grasa (si existe)
          if (bodyFat != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '% Grasa Corporal',
                  style: textTheme.bodyMedium?.copyWith(fontSize: 13.w),
                ),
                Text(
                  '$bodyFat%',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13.w,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
          ],
          // Masa magra (si existe)
          if (muscleMass != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Masa Magra',
                  style: textTheme.bodyMedium?.copyWith(fontSize: 13.w),
                ),
                Text(
                  '$muscleMass%',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13.w,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Card: Medidas corporales
  Widget _buildBodyMeasurementsCard(BuildContext context, snapshot) {
    final textTheme = Theme.of(context).textTheme;
    final latest = snapshot.latestAnthropometry;
    if (latest == null) return SizedBox.shrink();

    final measures = <String, dynamic>{
      'Cintura': latest['waist'],
      'Cadera': latest['hip'],
      'Brazo': latest['arm'],
      'Muslo': latest['thigh'],
    };

    final visibleMeasures =
        measures.entries.where((e) => e.value != null).toList();

    if (visibleMeasures.isEmpty) return SizedBox.shrink();

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
            'Medidas Corporales',
            style: textTheme.titleSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 14.w,
            ),
          ),
          SizedBox(height: 12.h),
          ...visibleMeasures.asMap().entries.map((entry) {
            final idx = entry.key;
            final measure = entry.value;
            final isLast = idx == visibleMeasures.length - 1;

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      measure.key,
                      style: textTheme.bodyMedium?.copyWith(fontSize: 13.w),
                    ),
                    Text(
                      '${measure.value} cm',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 13.w,
                      ),
                    ),
                  ],
                ),
                if (!isLast) SizedBox(height: 8.h),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Card: Interpretación antropométrica
  Widget _buildInterpretationCard(BuildContext context, snapshot) {
    final textTheme = Theme.of(context).textTheme;
    final latest = snapshot.latestAnthropometry;
    final interpretation = latest?['interpretation'] as String?;

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
              Icon(Icons.info_outline, size: 18.w, color: AppTheme.primaryGold),
              SizedBox(width: 8.w),
              Text(
                'Interpretación',
                style: textTheme.titleSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 14.w,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            interpretation != null && interpretation.trim().isNotEmpty
                ? interpretation
                : 'La interpretación antropométrica será realizada por tu coach.',
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 13.w,
              color: interpretation != null && interpretation.trim().isNotEmpty
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ======== NUEVO: helpers de adherencia (sin modificar layout) ========

  List<String> _extractMealKeys(dynamic planData) {
    final keys = <String>[];
    if (planData is Map) {
      final mealKeys = [
        'breakfast',
        'desayuno',
        'lunch',
        'almuerzo',
        'snack',
        'merienda',
        'dinner',
        'cena',
      ];
      for (final k in planData.keys) {
        final lk = k.toString().toLowerCase();
        if (mealKeys.any((mk) => lk.contains(mk))) {
          keys.add(k.toString());
        }
      }
    } else if (planData is List) {
      for (final item in planData) {
        if (item is Map && item['name'] != null) {
          keys.add(item['name'].toString());
        }
      }
    }
    return keys;
  }

  Future<void> _showAdherenceSelector(
      BuildContext context, List<String> mealKeys) async {
    String selectedMeal = mealKeys.first;
    int selectedPct = 80; // valor por defecto razonable
    final pctSteps = const [0, 20, 40, 60, 80, 100];

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12.r))),
      builder: (ctx) {
        final textTheme = Theme.of(ctx).textTheme;
        return Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.restaurant,
                      size: 18.w, color: AppTheme.primaryGold),
                  SizedBox(width: 8.w),
                  Text('Registrar adherencia',
                      style: textTheme.titleSmall?.copyWith(fontSize: 14.w)),
                ],
              ),
              SizedBox(height: 12.h),
              // Selector de comida
              DropdownButtonFormField<String>(
                initialValue: selectedMeal,
                items: mealKeys
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) selectedMeal = v;
                },
                decoration: InputDecoration(
                  labelText: 'Comida',
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
              SizedBox(height: 12.h),
              // Selector porcentaje (discreto en pasos de 20)
              DropdownButtonFormField<int>(
                initialValue: selectedPct,
                items: pctSteps
                    .map((p) => DropdownMenuItem(value: p, child: Text('$p%')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) selectedPct = v;
                },
                decoration: InputDecoration(
                  labelText: 'Adherencia',
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Escritura vía data layer (sin Firestore directo)
                    final service = ClientDataService();
                    await service.upsertNutritionAdherenceForDay(
                      date: DateTime.now(),
                      mealsPercentages: {selectedMeal: selectedPct},
                    );
                    if (context.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Adherencia guardada: $selectedMeal → $selectedPct%')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                  ),
                  child: Text('Guardar',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.w)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
