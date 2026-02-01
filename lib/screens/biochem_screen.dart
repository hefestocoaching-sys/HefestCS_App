import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hefestocs/constants/colors.dart';
import 'package:hefestocs/providers/client_store.dart';
import 'package:provider/provider.dart';

class BiochemScreen extends StatelessWidget {
  const BiochemScreen({super.key});

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
            'Error al cargar estudios bioquímicos',
            style: textTheme.bodyMedium?.copyWith(color: Colors.red),
          ),
        ),
      );
    }

    // Sin estudios bioquímicos
    if (!snapshot.hasBiochemistry || snapshot.latestBiochemistry == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Estudios Bioquímicos',
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
                      Icons.science_outlined,
                      size: 48.w,
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Aún no se han cargado estudios bioquímicos.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 14.w,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Cuando tu coach cargue los resultados, verás aquí los marcadores.',
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

    // Con estudios disponibles
    final biochemData = snapshot.latestBiochemistry!;
    final studyDate = _parseDate(biochemData['date'] as String?);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Estudios Bioquímicos',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22.w,
              ),
            ),
            SizedBox(height: 16.h),

            // Card 1: Estado general
            _buildStatusCard(context, snapshot, biochemData, studyDate),
            SizedBox(height: 12.h),

            // Card 2: Marcadores clave
            _buildMarkersCard(context, biochemData),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  /// Card 1: Estado general del estudio
  Widget _buildStatusCard(
    BuildContext context,
    snapshot,
    Map<String, dynamic> biochemData,
    DateTime? studyDate,
  ) {
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
            'Último Estudio',
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
                studyDate != null
                    ? '${studyDate.day}/${studyDate.month}/${studyDate.year}'
                    : 'Fecha no especificada',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 14.w,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Estado de marcadores
          Row(
            children: [
              Icon(Icons.info_outline, size: 16.w, color: AppTheme.primaryGold),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  _getOverallStatus(biochemData),
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14.w,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Card 2: Marcadores clave (máximo 5-7)
  Widget _buildMarkersCard(
      BuildContext context, Map<String, dynamic> biochemData) {
    final textTheme = Theme.of(context).textTheme;
    final markers = _extractMarkers(biochemData);

    if (markers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Text(
          'No hay marcadores disponibles',
          style: textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 14.w,
          ),
        ),
      );
    }

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
            'Marcadores Clave',
            style: textTheme.titleSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 14.w,
            ),
          ),
          SizedBox(height: 12.h),
          ...markers.asMap().entries.map((entry) {
            final index = entry.key;
            final marker = entry.value;
            final isLast = index == markers.length - 1;

            return Column(
              children: [
                _buildMarkerRow(context, marker),
                if (!isLast) SizedBox(height: 12.h),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Fila individual de marcador
  Widget _buildMarkerRow(BuildContext context, Map<String, dynamic> marker) {
    final textTheme = Theme.of(context).textTheme;
    final name = marker['name'] as String? ?? '';
    final value = marker['value'] as String? ?? '—';
    final status = marker['status'] as String? ?? 'normal';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 13.w,
                ),
              ),
              Text(
                value,
                style: textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11.w,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: _getStatusColor(status),
              width: 1,
            ),
          ),
          child: Text(
            _formatStatus(status),
            style: textTheme.bodySmall?.copyWith(
              color: _getStatusColor(status),
              fontWeight: FontWeight.w500,
              fontSize: 10.w,
            ),
          ),
        ),
      ],
    );
  }

  /// Extrae los marcadores (máximo 5-7 primeros)
  List<Map<String, dynamic>> _extractMarkers(Map<String, dynamic> biochemData) {
    final markers = <Map<String, dynamic>>[];
    final keysToCheck = [
      'glucose',
      'cholesterol',
      'triglycerides',
      'hdl',
      'ldl',
      'hemoglobin',
      'creatinine',
    ];

    for (final key in keysToCheck) {
      if (biochemData.containsKey(key) && biochemData[key] != null) {
        final markerData = biochemData[key];
        if (markerData is Map<String, dynamic>) {
          markers.add({
            'name': _getMarkerName(key),
            'value': markerData['value']?.toString() ?? '—',
            'status': markerData['status']?.toString() ?? 'normal',
          });
        }
      }
    }

    return markers.take(7).toList();
  }

  /// Obtiene nombre legible del marcador
  String _getMarkerName(String key) {
    final names = {
      'glucose': 'Glucosa',
      'cholesterol': 'Colesterol Total',
      'triglycerides': 'Triglicéridos',
      'hdl': 'HDL (Colesterol Bueno)',
      'ldl': 'LDL (Colesterol Malo)',
      'hemoglobin': 'Hemoglobina',
      'creatinine': 'Creatinina',
    };
    return names[key] ?? key;
  }

  /// Estado general del estudio
  String _getOverallStatus(Map<String, dynamic> biochemData) {
    int outOfRangeCount = 0;
    int totalMarkers = 0;

    final keysToCheck = [
      'glucose',
      'cholesterol',
      'triglycerides',
      'hdl',
      'ldl',
      'hemoglobin',
      'creatinine',
    ];

    for (final key in keysToCheck) {
      if (biochemData.containsKey(key) && biochemData[key] != null) {
        final markerData = biochemData[key];
        if (markerData is Map<String, dynamic>) {
          totalMarkers++;
          final status = markerData['status']?.toString() ?? 'normal';
          if (status.toLowerCase() != 'normal') {
            outOfRangeCount++;
          }
        }
      }
    }

    if (totalMarkers == 0) {
      return 'Sin información de marcadores';
    }

    if (outOfRangeCount == 0) {
      return 'Marcadores dentro de rango';
    }

    return 'Algunos valores fuera de rango';
  }

  /// Obtiene color del estado
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'high':
      case 'alto':
        return Colors.red;
      case 'low':
      case 'bajo':
        return Colors.orange;
      case 'normal':
      default:
        return Colors.green;
    }
  }

  /// Formatea el estado para mostrar
  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'high':
      case 'alto':
        return 'Alto';
      case 'low':
      case 'bajo':
        return 'Bajo';
      case 'normal':
      default:
        return 'Normal';
    }
  }

  /// Parsea fecha de string
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }
}
