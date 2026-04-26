import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hefestocs/constants/colors.dart';
import 'package:hefestocs/models/exercise_preferences.dart';

/// Screen para que el cliente seleccione sus preferencias de ejercicios
/// por cada grupo muscular (14 músculos)
class ExercisePreferencesScreen extends StatefulWidget {
  final ExercisePreferencesByMuscle? initialPreferences;
  final void Function(ExercisePreferencesByMuscle) onSave;

  const ExercisePreferencesScreen({
    super.key,
    this.initialPreferences,
    required this.onSave,
  });

  @override
  State<ExercisePreferencesScreen> createState() =>
      _ExercisePreferencesScreenState();
}

class _ExercisePreferencesScreenState extends State<ExercisePreferencesScreen> {
  late Map<String, String?>
  _preferences; // muscleKey -> selection (frequent/preferred/avoid/null)
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialPreferences();
  }

  void _loadInitialPreferences() {
    _preferences = {};
    for (final group in kExercisePreferenceGroups) {
      for (final muscleKey in group.persistMuscleKeys) {
        final bucket = widget.initialPreferences?.byMuscle[muscleKey];
        if (bucket?.frequent.isNotEmpty ?? false) {
          _preferences[muscleKey] = 'frequent';
        } else if (bucket?.preferred.isNotEmpty ?? false) {
          _preferences[muscleKey] = 'preferred';
        } else if (bucket?.avoid.isNotEmpty ?? false) {
          _preferences[muscleKey] = 'avoid';
        } else {
          _preferences[muscleKey] = null;
        }
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);

    try {
      // Construir ExercisePreferencesByMuscle desde selecciones
      final byMuscle = <String, ExercisePreferenceBucket>{};

      for (final entry in _preferences.entries) {
        final muscleKey = entry.key;
        final selection = entry.value;

        if (selection == 'frequent') {
          byMuscle[muscleKey] = ExercisePreferenceBucket(
            frequent: {'placeholder'}, // El motor llenará esto
          );
        } else if (selection == 'preferred') {
          byMuscle[muscleKey] = ExercisePreferenceBucket(
            preferred: {'placeholder'},
          );
        } else if (selection == 'avoid') {
          byMuscle[muscleKey] = ExercisePreferenceBucket(
            avoid: {'placeholder'},
          );
        }
      }

      final prefs = ExercisePreferencesByMuscle(byMuscle: byMuscle);
      widget.onSave(prefs);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Preferencias guardadas'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.wrapperBackground,
      appBar: AppBar(
        title: const Text('Preferencias de Ejercicios'),
        backgroundColor: AppTheme.navBar,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecciona tu preferencia para cada grupo muscular',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            SizedBox(height: 20.h),
            ..._buildMuscleCards(),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.black,
                          ),
                        ),
                      )
                    : Text(
                        'Guardar Preferencias',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMuscleCards() {
    return kExercisePreferenceGroups.map((group) {
      return _MusclePreferenceCard(
        group: group,
        selection: _preferences[group.persistMuscleKeys.first] ?? 'neutral',
        onChanged: (selection) {
          setState(() {
            for (final key in group.persistMuscleKeys) {
              _preferences[key] = selection == 'neutral' ? null : selection;
            }
          });
        },
      );
    }).toList();
  }
}

/// Widget individual para cada grupo muscular
class _MusclePreferenceCard extends StatelessWidget {
  final ExercisePreferenceGroup group;
  final String selection; // 'frequent' | 'preferred' | 'avoid' | 'neutral'
  final void Function(String) onChanged;

  const _MusclePreferenceCard({
    required this.group,
    required this.selection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: selection == 'neutral'
              ? Colors.transparent
              : AppTheme.primaryGold,
          width: selection == 'neutral' ? 1 : 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14.w,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PreferenceButton(
                label: 'Frecuente',
                isSelected: selection == 'frequent',
                color: Colors.green,
                onTap: () => onChanged('frequent'),
              ),
              _PreferenceButton(
                label: 'Preferido',
                isSelected: selection == 'preferred',
                color: AppTheme.primaryGold,
                onTap: () => onChanged('preferred'),
              ),
              _PreferenceButton(
                label: 'Evitar',
                isSelected: selection == 'avoid',
                color: Colors.red,
                onTap: () => onChanged('avoid'),
              ),
              _PreferenceButton(
                label: 'Neutral',
                isSelected: selection == 'neutral',
                color: AppTheme.textSecondary,
                onTap: () => onChanged('neutral'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Botón individual para cada preferencia
class _PreferenceButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _PreferenceButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
            border: Border.all(color: color, width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11.w,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
