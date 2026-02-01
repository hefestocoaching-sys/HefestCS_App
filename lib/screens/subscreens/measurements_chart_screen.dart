// lib/screens/subscreens/measurements_chart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hefestocs/constants/colors.dart';
import 'package:hefestocs/providers/client_store.dart';
import 'package:provider/provider.dart';

class MeasurementsChartScreen extends StatelessWidget {
  const MeasurementsChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final clientStore = context.watch<ClientStore>();
    final snapshot = clientStore.snapshot;

    // Loading
    if (clientStore.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryGold,
        ),
      );
    }

    // Error
    if (clientStore.error != null || snapshot == null) {
      return Center(
        child: Text(
          'Error al cargar mediciones',
          style: textTheme.bodyMedium?.copyWith(color: Colors.red),
        ),
      );
    }

    // Verificar si hay datos suficientes
    final sortedHistory = snapshot.anthropometryHistorySorted;
    if (sortedHistory.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up_outlined,
              size: 48.w,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              'Datos insuficientes',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Necesitas al menos 2 registros para visualizar la evolución.',
              style: textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen
          _buildSummaryCard(context, snapshot, sortedHistory),
          SizedBox(height: 20.h),

          // Gráfica 1: Peso
          _buildWeightChart(context, sortedHistory),
          SizedBox(height: 20.h),

          // Gráfica 2: Grasa corporal (si existe)
          if (_hasBodyFatData(sortedHistory)) ...[
            _buildBodyFatChart(context, sortedHistory),
            SizedBox(height: 20.h),
          ],

          // Gráfica 3: Masa magra (si existe)
          if (_hasMuscleMassData(sortedHistory)) ...[
            _buildMuscleMassChart(context, sortedHistory),
            SizedBox(height: 20.h),
          ],
        ],
      ),
    );
  }

  /// Card de resumen
  Widget _buildSummaryCard(
    BuildContext context,
    snapshot,
    List<Map<String, dynamic>> sortedHistory,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final latest = sortedHistory.last;
    final previous = sortedHistory.length >= 2
        ? sortedHistory[sortedHistory.length - 2]
        : null;

    final latestWeight = (latest['weight'] as num?)?.toDouble() ?? 0.0;
    final previousWeight = (previous?['weight'] as num?)?.toDouble();
    final weightChange =
        previousWeight != null ? latestWeight - previousWeight : null;

    final latestDateStr = latest['date'] as String?;
    final latestDate =
        latestDateStr != null ? DateTime.tryParse(latestDateStr) : null;

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
            'Últimas Mediciones',
            style: textTheme.titleSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 14.w,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peso actual',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 12.w,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${latestWeight.toStringAsFixed(1)} kg',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 24.w,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (weightChange != null) ...[
                    Text(
                      'Cambio',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 12.w,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          weightChange > 0
                              ? Icons.trending_up
                              : weightChange < 0
                                  ? Icons.trending_down
                                  : Icons.trending_flat,
                          size: 20.w,
                          color: weightChange > 0
                              ? Colors.red
                              : weightChange < 0
                                  ? Colors.green
                                  : Colors.blue,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${weightChange.abs().toStringAsFixed(1)} kg',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.w,
                            color: weightChange > 0
                                ? Colors.red
                                : weightChange < 0
                                    ? Colors.green
                                    : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 14.w, color: AppTheme.primaryGold),
              SizedBox(width: 6.w),
              Text(
                latestDate != null
                    ? '${latestDate.day}/${latestDate.month}/${latestDate.year}'
                    : 'Fecha no disponible',
                style: textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 12.w,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Gráfica de peso
  Widget _buildWeightChart(
    BuildContext context,
    List<Map<String, dynamic>> sortedHistory,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final weights = sortedHistory
        .map((m) => (m['weight'] as num?)?.toDouble() ?? 0.0)
        .toList();

    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);

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
            'Evolución de Peso',
            style: textTheme.titleSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 14.w,
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 200.h,
            child: CustomPaint(
              painter: LineChartPainter(
                values: weights,
                color: AppTheme.primaryGold,
                minValue: minWeight,
                maxValue: maxWeight,
              ),
              size: Size(double.infinity, 200.h),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mín: ${minWeight.toStringAsFixed(1)} kg',
                style: textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11.w,
                ),
              ),
              Text(
                'Máx: ${maxWeight.toStringAsFixed(1)} kg',
                style: textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11.w,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Gráfica de grasa corporal
  Widget _buildBodyFatChart(
    BuildContext context,
    List<Map<String, dynamic>> sortedHistory,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final bodyFatValues = sortedHistory
        .map((m) => (m['bodyFatPercentage'] as num?)?.toDouble() ?? 0.0)
        .toList();

    final minFat = bodyFatValues.reduce((a, b) => a < b ? a : b);
    final maxFat = bodyFatValues.reduce((a, b) => a > b ? a : b);

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
            'Porcentaje de Grasa Corporal',
            style: textTheme.titleSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 14.w,
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 200.h,
            child: CustomPaint(
              painter: LineChartPainter(
                values: bodyFatValues,
                color: Colors.orange,
                minValue: minFat,
                maxValue: maxFat,
              ),
              size: Size(double.infinity, 200.h),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mín: ${minFat.toStringAsFixed(1)}%',
                style: textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11.w,
                ),
              ),
              Text(
                'Máx: ${maxFat.toStringAsFixed(1)}%',
                style: textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11.w,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Gráfica de masa magra
  Widget _buildMuscleMassChart(
    BuildContext context,
    List<Map<String, dynamic>> sortedHistory,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final muscleMassValues = sortedHistory
        .map((m) => (m['muscleMassPercentage'] as num?)?.toDouble() ?? 0.0)
        .toList();

    final minMuscle = muscleMassValues.reduce((a, b) => a < b ? a : b);
    final maxMuscle = muscleMassValues.reduce((a, b) => a > b ? a : b);

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
            'Porcentaje de Masa Magra',
            style: textTheme.titleSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 14.w,
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 200.h,
            child: CustomPaint(
              painter: LineChartPainter(
                values: muscleMassValues,
                color: Colors.green,
                minValue: minMuscle,
                maxValue: maxMuscle,
              ),
              size: Size(double.infinity, 200.h),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mín: ${minMuscle.toStringAsFixed(1)}%',
                style: textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11.w,
                ),
              ),
              Text(
                'Máx: ${maxMuscle.toStringAsFixed(1)}%',
                style: textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11.w,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Verifica si hay datos de grasa corporal
  bool _hasBodyFatData(List<Map<String, dynamic>> history) {
    return history.any((m) => m['bodyFatPercentage'] != null);
  }

  /// Verifica si hay datos de masa magra
  bool _hasMuscleMassData(List<Map<String, dynamic>> history) {
    return history.any((m) => m['muscleMassPercentage'] != null);
  }
}

/// Custom painter para gráficas de línea simples
class LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double minValue;
  final double maxValue;

  LineChartPainter({
    required this.values,
    required this.color,
    required this.minValue,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    final range = maxValue - minValue;
    final padding = 20.0;
    final chartWidth = size.width - (padding * 2);
    final chartHeight = size.height - (padding * 2);

    // Dibujar grid horizontal
    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // Calcular puntos
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = padding + (chartWidth / (values.length - 1)) * i;
      final normalizedValue = (values[i] - minValue) / range;
      final y = padding + chartHeight - (normalizedValue * chartHeight);
      points.add(Offset(x, y));
    }

    // Dibujar línea
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Dibujar puntos
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
