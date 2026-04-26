import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hefestocs/constants/colors.dart';
import 'package:hefestocs/models/client_snapshot.dart';
import 'package:hefestocs/providers/client_store.dart';
import 'package:provider/provider.dart';

class EquivalentsScreen extends StatefulWidget {
  const EquivalentsScreen({super.key});

  @override
  State<EquivalentsScreen> createState() => _EquivalentsScreenState();
}

class _EquivalentsScreenState extends State<EquivalentsScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  List<String> _days = [];

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _syncTabs(List<String> days) {
    if (_days.length == days.length && _days.join('|') == days.join('|')) {
      return;
    }

    _days = days;
    _tabController?.dispose();
    _tabController = days.isEmpty
        ? null
        : TabController(length: days.length, vsync: this, initialIndex: 0);
  }

  @override
  Widget build(BuildContext context) {
    final clientStore = context.watch<ClientStore>();
    final snapshot = clientStore.snapshot;
    final textTheme = Theme.of(context).textTheme;

    if (clientStore.isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGold),
        ),
      );
    }

    if (clientStore.error != null || snapshot == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text(
            'Error al cargar equivalentes',
            style: textTheme.bodyLarge?.copyWith(color: Colors.red),
          ),
        ),
      );
    }

    final days = snapshot.smaeDays;
    _syncTabs(days);

    if (!snapshot.hasSmaePlan || days.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: EdgeInsets.all(16.w),
          child: _buildEmptyState(context),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 6.h),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Equivalentes SMAE v2',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.w,
                ),
              ),
            ),
          ),
          if (_tabController != null)
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppTheme.primaryGold,
              unselectedLabelColor:
                  AppTheme.textSecondary.withValues(alpha: 0.75),
              indicatorColor: AppTheme.primaryGold,
              tabs: days
                  .map((day) => Tab(text: snapshot.prettyDayName(day)))
                  .toList(),
            ),
          SizedBox(height: 8.h),
          Expanded(
            child: _tabController == null
                ? const SizedBox.shrink()
                : TabBarView(
                    controller: _tabController,
                    children: days
                        .map((day) => _buildDayView(context, snapshot, day))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fact_check_outlined,
              size: 48.w, color: AppTheme.primaryGold),
          SizedBox(height: 10.h),
          Text(
            'Plan SMAE no configurado',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16.w,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'Tu coach aún no ha sincronizado equivalentes por día/comida. Cuando esté listo, verás aquí cobertura y detalle por grupo.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 13.w,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayView(
    BuildContext context,
    ClientSnapshot snapshot,
    String day,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final meals = snapshot.mealsForDay(day);
    final equivalents = snapshot.equivalentsForDay(day);
    final kcalByGroup = snapshot.kcalByGroupForDay(day);
    final warnings = snapshot.planWarningsForDay(day);
    final kcal = snapshot.calculatedKcalForDay(day);
    final delta = snapshot.kcalDeltaForDay(day);
    final target = snapshot.kcalTarget;
    final coverage = snapshot.coveragePercentForDay(day);
    final level = snapshot.coverageLevelForDay(day);
    final levelColor = _coverageColor(level);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
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
                      'Cobertura diaria',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.w,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: levelColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999.r),
                        border: Border.all(color: levelColor, width: 1),
                      ),
                      child: Text(
                        _coverageLabel(level),
                        style: textTheme.bodySmall?.copyWith(
                          color: levelColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.w,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: LinearProgressIndicator(
                    minHeight: 8.h,
                    value: (coverage / 100).clamp(0.0, 1.0),
                    backgroundColor:
                        AppTheme.textSecondary.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                  ),
                ),
                SizedBox(height: 10.h),
                Wrap(
                  spacing: 12.w,
                  runSpacing: 8.h,
                  children: [
                    _metricChip(context, 'Objetivo',
                        '${target.toStringAsFixed(0)} kcal'),
                    _metricChip(context, 'Calculado',
                        '${kcal.toStringAsFixed(0)} kcal'),
                    _metricChip(
                      context,
                      'Delta',
                      '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(0)} kcal',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (warnings.isNotEmpty) ...[
            SizedBox(height: 10.h),
            ...warnings.map(
              (warning) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    warning,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 12.w,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: 12.h),
          Text(
            'Comidas del día',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15.w,
            ),
          ),
          SizedBox(height: 8.h),
          if (meals.isEmpty)
            _emptyLine(context, 'Sin comidas configuradas para este día.'),
          ...meals.entries.map(
            (mealEntry) =>
                _mealCard(context, snapshot, mealEntry.key, mealEntry.value),
          ),
          SizedBox(height: 12.h),
          Text(
            'Equivalentes por grupo',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15.w,
            ),
          ),
          SizedBox(height: 8.h),
          if (equivalents.isEmpty)
            _emptyLine(context, 'No hay equivalentes por grupo para este día.'),
          if (equivalents.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: equivalents.entries.map((entry) {
                  final group = snapshot.prettyGroupName(entry.key);
                  final qty = entry.value;
                  final estKcal = kcalByGroup[entry.key] ?? 0;
                  return ListTile(
                    dense: true,
                    title: Text(
                      group,
                      style: textTheme.bodyMedium?.copyWith(fontSize: 13.w),
                    ),
                    subtitle: Text(
                      '${qty.toStringAsFixed(2)} eq',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary.withValues(alpha: 0.85),
                        fontSize: 11.w,
                      ),
                    ),
                    trailing: Text(
                      '${estKcal.isFinite ? estKcal.toStringAsFixed(0) : '0'} kcal',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.w,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          SizedBox(height: 12.h),
          Text(
            'Edición próximamente: podrás ajustar equivalentes y alimentos por comida.',
            style: textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary.withValues(alpha: 0.75),
              fontSize: 11.w,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealCard(
    BuildContext context,
    ClientSnapshot snapshot,
    String mealName,
    Map<String, double> groups,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            snapshot.prettyMealName(mealName),
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14.w,
            ),
          ),
          SizedBox(height: 6.h),
          if (groups.isEmpty) _emptyLine(context, 'Sin grupos en esta comida.'),
          ...groups.entries.map(
            (groupEntry) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      snapshot.prettyGroupName(groupEntry.key),
                      style: textTheme.bodySmall?.copyWith(fontSize: 12.w),
                    ),
                  ),
                  Text(
                    '${groupEntry.value.toStringAsFixed(2)} eq',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.w,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(BuildContext context, String title, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTransparent,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        '$title: $value',
        style: textTheme.bodySmall?.copyWith(
          fontSize: 11.w,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _emptyLine(BuildContext context, String text) {
    final textTheme = Theme.of(context).textTheme;
    return Text(
      text,
      style: textTheme.bodySmall?.copyWith(
        color: AppTheme.textSecondary.withValues(alpha: 0.75),
        fontSize: 12.w,
      ),
    );
  }

  String _coverageLabel(String level) {
    switch (level) {
      case 'green':
        return 'Óptimo';
      case 'orange':
        return 'Ajustar';
      default:
        return 'Crítico';
    }
  }

  Color _coverageColor(String level) {
    switch (level) {
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}
