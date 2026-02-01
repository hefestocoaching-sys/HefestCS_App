// lib/screens/subscreens/measurements_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hefestocs/constants/colors.dart';
import 'package:hefestocs/providers/client_store.dart';
import 'package:provider/provider.dart';

class MeasurementsScreen extends StatelessWidget {
  const MeasurementsScreen({super.key});

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
            'Error al cargar mediciones',
            style: textTheme.bodyMedium?.copyWith(color: Colors.red),
          ),
        ),
      );
    }

    // Sin mediciones
    if (snapshot.latestAnthropometry == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Mediciones Antropométricas',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22.w,
                ),
              ),
              SizedBox(height: 16.h),

              // Card informativa
              Container(
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
                      Icons.straighten_outlined,
                      size: 48.w,
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Sin mediciones registradas',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 14.w,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Cuando tu coach realice las mediciones, verás aquí los detalles.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary.withValues(alpha: 0.7),
                        fontSize: 12.w,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      );
    }

    // Con mediciones disponibles
    final latestMeasurement = snapshot.latestAnthropometry!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Mediciones Antropométricas',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22.w,
              ),
            ),
            SizedBox(height: 16.h),

            // A) Encabezado: Fecha y método
            _buildHeaderCard(context, latestMeasurement),
            SizedBox(height: 12.h),

            // B) Pliegues cutáneos (si existen)
            if (_hasSkinfolds(latestMeasurement)) ...[
              _buildSkinfoldSection(context, latestMeasurement),
              SizedBox(height: 12.h),
            ],

            // C) Circunferencias (si existen)
            if (_hasCircumferences(latestMeasurement)) ...[
              _buildCircumferenceSection(context, latestMeasurement),
              SizedBox(height: 12.h),
            ],

            // D) Composición corporal
            _buildBodyCompositionCard(context, latestMeasurement),
            SizedBox(height: 12.h),

            // E) Interpretación
            _buildInterpretationCard(context, latestMeasurement),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  /// A) Card: Encabezado con fecha y método
  Widget _buildHeaderCard(
    BuildContext context,
    Map<String, dynamic> measurement,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final dateStr = measurement['date'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final method = measurement['method'] as String?;

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
            'Última Medición',
            style: textTheme.titleSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 14.w,
            ),
          ),
          SizedBox(height: 12.h),
          // Fecha
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 16.w, color: AppTheme.primaryGold),
              SizedBox(width: 8.w),
              Text(
                date != null
                    ? '${date.day}/${date.month}/${date.year}'
                    : 'Fecha no especificada',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 14.w,
                ),
              ),
            ],
          ),
          // Método (si existe)
          if (method != null && method.trim().isNotEmpty) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.analytics_outlined,
                    size: 16.w, color: AppTheme.primaryGold),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    method,
                    style: textTheme.bodyMedium?.copyWith(fontSize: 13.w),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// B) Sección: Pliegues cutáneos
  Widget _buildSkinfoldSection(
    BuildContext context,
    Map<String, dynamic> measurement,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final skinfolds = _extractSkinfolds(measurement);

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
            'Pliegues Cutáneos',
            style: textTheme.titleSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 14.w,
            ),
          ),
          SizedBox(height: 12.h),
          ...skinfolds.asMap().entries.map((entry) {
            final index = entry.key;
            final skinfold = entry.value;
            final isLast = index == skinfolds.length - 1;

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getSkinfoldLabel(skinfold['key']),
                      style: textTheme.bodyMedium?.copyWith(fontSize: 13.w),
                    ),
                    Text(
                      '${skinfold['value']} mm',
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

  /// C) Sección: Circunferencias
  Widget _buildCircumferenceSection(
    BuildContext context,
    Map<String, dynamic> measurement,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final circumferences = _extractCircumferences(measurement);

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
            'Circunferencias',
            style: textTheme.titleSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 14.w,
            ),
          ),
          SizedBox(height: 12.h),
          ...circumferences.asMap().entries.map((entry) {
            final index = entry.key;
            final circ = entry.value;
            final isLast = index == circumferences.length - 1;

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getCircumferenceLabel(circ['key']),
                      style: textTheme.bodyMedium?.copyWith(fontSize: 13.w),
                    ),
                    Text(
                      '${circ['value']} cm',
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

  /// D) Card: Composición corporal
  Widget _buildBodyCompositionCard(
    BuildContext context,
    Map<String, dynamic> measurement,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final weight = (measurement['weight'] as num?)?.toDouble();
    final bodyFat = measurement['bodyFatPercentage'] as dynamic;
    final muscleMass = measurement['muscleMassPercentage'] as dynamic;
    final fatMass = measurement['fatMass'] as dynamic;

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
            'Composición Corporal',
            style: textTheme.titleSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 14.w,
            ),
          ),
          SizedBox(height: 12.h),
          // Peso
          if (weight != null) ...[
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
          ],
          // % Grasa
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
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
          ],
          // Masa magra
          if (muscleMass != null) ...[
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
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
          ],
          // Masa grasa (si existe)
          if (fatMass != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Masa Grasa',
                  style: textTheme.bodyMedium?.copyWith(fontSize: 13.w),
                ),
                Text(
                  '$fatMass kg',
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

  /// E) Card: Interpretación antropométrica
  Widget _buildInterpretationCard(
    BuildContext context,
    Map<String, dynamic> measurement,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final interpretation = measurement['interpretation'] as String?;

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
                'Interpretación Antropométrica',
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

  /// Verifica si hay pliegues cutáneos
  bool _hasSkinfolds(Map<String, dynamic> measurement) {
    final skinfoldKeys = [
      'triceps',
      'biceps',
      'subscapular',
      'suprailiac',
      'abdominal',
      'thigh',
      'calf',
      'chest',
      'midaxillary',
    ];
    return skinfoldKeys.any((key) => measurement[key] != null);
  }

  /// Verifica si hay circunferencias
  bool _hasCircumferences(Map<String, dynamic> measurement) {
    final circumferenceKeys = [
      'waist',
      'hip',
      'arm',
      'forearm',
      'thighCirc',
      'calfCirc',
      'neck',
      'chest',
      'shoulder',
    ];
    return circumferenceKeys.any((key) => measurement[key] != null);
  }

  /// Extrae pliegues cutáneos existentes
  List<Map<String, dynamic>> _extractSkinfolds(
      Map<String, dynamic> measurement) {
    final skinfoldKeys = [
      'triceps',
      'biceps',
      'subscapular',
      'suprailiac',
      'abdominal',
      'thigh',
      'calf',
      'chest',
      'midaxillary',
    ];

    final skinfolds = <Map<String, dynamic>>[];
    for (final key in skinfoldKeys) {
      if (measurement.containsKey(key) && measurement[key] != null) {
        skinfolds.add({
          'key': key,
          'value': measurement[key],
        });
      }
    }
    return skinfolds;
  }

  /// Extrae circunferencias existentes
  List<Map<String, dynamic>> _extractCircumferences(
      Map<String, dynamic> measurement) {
    final circumferenceKeys = [
      'waist',
      'hip',
      'arm',
      'forearm',
      'thighCirc',
      'calfCirc',
      'neck',
      'chest',
      'shoulder',
    ];

    final circumferences = <Map<String, dynamic>>[];
    for (final key in circumferenceKeys) {
      if (measurement.containsKey(key) && measurement[key] != null) {
        circumferences.add({
          'key': key,
          'value': measurement[key],
        });
      }
    }
    return circumferences;
  }

  /// Obtiene etiqueta legible para pliegue
  String _getSkinfoldLabel(String key) {
    final labels = {
      'triceps': 'Tríceps',
      'biceps': 'Bíceps',
      'subscapular': 'Subescapular',
      'suprailiac': 'Suprailiaco',
      'abdominal': 'Abdominal',
      'thigh': 'Muslo',
      'calf': 'Pantorrilla',
      'chest': 'Pecho',
      'midaxillary': 'Axilar Medio',
    };
    return labels[key] ?? key;
  }

  /// Obtiene etiqueta legible para circunferencia
  String _getCircumferenceLabel(String key) {
    final labels = {
      'waist': 'Cintura',
      'hip': 'Cadera',
      'arm': 'Brazo',
      'forearm': 'Antebrazo',
      'thighCirc': 'Muslo',
      'calfCirc': 'Pantorrilla',
      'neck': 'Cuello',
      'chest': 'Pecho',
      'shoulder': 'Hombro',
    };
    return labels[key] ?? key;
  }
}
