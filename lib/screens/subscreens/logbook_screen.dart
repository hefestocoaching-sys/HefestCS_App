// lib/screens/subscreens/logbook_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hefestocs/constants/colors.dart';
import 'package:hefestocs/providers/client_store.dart';
import 'package:hefestocs/services/client_data_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class LogbookScreen extends StatefulWidget {
  const LogbookScreen({super.key});

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> {
  DateTime _selectedDate = DateTime.now();

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
            'Error al cargar bitácora',
            style: textTheme.bodyMedium?.copyWith(color: Colors.red),
          ),
        ),
      );
    }

    // Obtener plan de entrenamiento del payload
    final trainingData =
        snapshot.rawPayload?['training'] as Map<String, dynamic>?;
    final program = trainingData?['program'] as Map<String, dynamic>?;

    // Sin plan de entrenamiento
    if (program == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bitácora de Entrenamiento',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22.w,
                ),
              ),
              SizedBox(height: 16.h),
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
                      Icons.fitness_center_outlined,
                      size: 48.w,
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'No tienes un plan de entrenamiento asignado.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 14.w,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Obtener el entrenamiento del día
    final todayTraining = _getTodayTraining(program, _selectedDate);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Bitácora de Entrenamiento',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22.w,
              ),
            ),
            SizedBox(height: 16.h),

            // Selector de fecha
            _buildDateSelector(context),
            SizedBox(height: 12.h),

            // Entrenamiento del día
            if (todayTraining != null)
              _buildWorkoutSection(context, todayTraining, clientStore)
            else
              _buildRestDayCard(context),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  /// Selector de fecha
  Widget _buildDateSelector(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: AppTheme.primaryGold),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(Duration(days: 1));
              });
            },
          ),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(Duration(days: 365)),
                lastDate: DateTime.now().add(Duration(days: 30)),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
            child: Column(
              children: [
                Text(
                  DateFormat('EEEE', 'es').format(_selectedDate),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 12.w,
                  ),
                ),
                Text(
                  DateFormat('d MMMM yyyy', 'es').format(_selectedDate),
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.w,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: AppTheme.primaryGold),
            onPressed: _selectedDate.isBefore(DateTime.now())
                ? () {
                    setState(() {
                      _selectedDate = _selectedDate.add(Duration(days: 1));
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  /// Card de día de descanso
  Widget _buildRestDayCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Icon(
            Icons.bedtime_outlined,
            size: 48.w,
            color: AppTheme.primaryGold,
          ),
          SizedBox(height: 12.h),
          Text(
            'Día de Descanso',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Aprovecha para recuperarte y regenerar.',
            style: textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Sección de entrenamiento del día
  Widget _buildWorkoutSection(
    BuildContext context,
    Map<String, dynamic> workout,
    ClientStore clientStore,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final exercises = workout['exercises'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título del día
        Container(
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
                workout['name'] as String? ?? 'Entrenamiento',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.w,
                ),
              ),
              if (workout['focus'] != null) ...[
                SizedBox(height: 4.h),
                Text(
                  workout['focus'] as String,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 12.w,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Ejercicios
        ...exercises.asMap().entries.map((entry) {
          final index = entry.key;
          final exercise = entry.value as Map<String, dynamic>;

          return Column(
            children: [
              _ExerciseCard(
                exercise: exercise,
                exerciseIndex: index,
                workoutId: workout['id'] as String? ??
                    'workout_${_selectedDate.toIso8601String()}',
                date: _selectedDate,
                clientStore: clientStore,
              ),
              SizedBox(height: 12.h),
            ],
          );
        }),
      ],
    );
  }

  /// Obtiene el entrenamiento del día según la fecha seleccionada
  Map<String, dynamic>? _getTodayTraining(
    Map<String, dynamic> program,
    DateTime date,
  ) {
    // Determinar día de la semana (1 = lunes, 7 = domingo)
    final weekday = date.weekday;

    // Buscar en el programa el día correspondiente
    final schedule = program['schedule'] as Map<String, dynamic>?;
    if (schedule == null) return null;

    // Mapear día de la semana a clave del programa
    final dayKey = _getDayKey(weekday);
    final workout = schedule[dayKey];

    if (workout == null) return null;
    if (workout is! Map<String, dynamic>) return null;

    return workout;
  }

  /// Mapea el día de la semana a la clave del programa
  String _getDayKey(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
  }
}

/// Widget para cada ejercicio con registro de sets
class _ExerciseCard extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final int exerciseIndex;
  final String workoutId;
  final DateTime date;
  final ClientStore clientStore;

  const _ExerciseCard({
    required this.exercise,
    required this.exerciseIndex,
    required this.workoutId,
    required this.date,
    required this.clientStore,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  List<Map<String, dynamic>> _sets = [];
  bool _isExpanded = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeSets();
  }

  void _initializeSets() {
    final plannedSets = widget.exercise['sets'] as int? ?? 3;
    _sets = List.generate(
      plannedSets,
      (index) => {
        'reps': widget.exercise['reps'] ?? 0,
        'load': 0.0,
        'rir': 2,
        'completed': false,
        'notes': '',
      },
    );
  }

  Future<void> _saveLog() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Construir log entries
      final logEntries = _sets.asMap().entries.map((entry) {
        final setIndex = entry.key;
        final set = entry.value;

        return {
          'date': widget.date.toIso8601String(),
          'workoutId': widget.workoutId,
          'exerciseId':
              widget.exercise['id'] ?? 'exercise_${widget.exerciseIndex}',
          'exerciseName': widget.exercise['name'] ?? 'Ejercicio',
          'setIndex': setIndex,
          'reps': set['reps'],
          'load': set['load'],
          'rir': set['rir'],
          'completed': set['completed'],
          'notes': set['notes'],
          'timestamp': DateTime.now().toIso8601String(),
        };
      }).toList();
      // Registrar vía capa de datos (subcolección training_logs por fecha)
      // - No escribir directo a Firestore desde UI
      // - No usar updatePayload para logs (legacy)
      final dataService = ClientDataService();
      await dataService.appendTrainingLogForDay(
        date: widget.date,
        entries: logEntries,
        // sessionCompleted: null (este botón guarda ejercicio, no toda la sesión)
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Entrenamiento registrado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final exerciseName = widget.exercise['name'] as String? ?? 'Ejercicio';
    final plannedSets = widget.exercise['sets'] ?? _sets.length;
    final plannedReps = widget.exercise['reps'] ?? '-';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Header del ejercicio
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exerciseName,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.w,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '$plannedSets sets × $plannedReps reps',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 12.w,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.primaryGold,
                  ),
                ],
              ),
            ),
          ),

          // Sets expandibles
          if (_isExpanded) ...[
            Divider(
                height: 1,
                color: AppTheme.textSecondary.withValues(alpha: 0.2)),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  // Encabezados
                  Row(
                    children: [
                      SizedBox(
                          width: 40.w,
                          child: Text('Set',
                              style: TextStyle(
                                  fontSize: 11.w,
                                  fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 50.w,
                          child: Text('Reps',
                              style: TextStyle(
                                  fontSize: 11.w,
                                  fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 60.w,
                          child: Text('Carga',
                              style: TextStyle(
                                  fontSize: 11.w,
                                  fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 50.w,
                          child: Text('RIR',
                              style: TextStyle(
                                  fontSize: 11.w,
                                  fontWeight: FontWeight.bold))),
                      SizedBox(
                          width: 40.w,
                          child: Text('✓',
                              style: TextStyle(
                                  fontSize: 11.w,
                                  fontWeight: FontWeight.bold))),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // Sets
                  ..._sets.asMap().entries.map((entry) {
                    final setIndex = entry.key;
                    final set = entry.value;

                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        children: [
                          // Set number
                          SizedBox(
                            width: 40.w,
                            child: Text('${setIndex + 1}',
                                style: TextStyle(fontSize: 12.w)),
                          ),
                          // Reps
                          SizedBox(
                            width: 50.w,
                            child: TextFormField(
                              initialValue: set['reps'].toString(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4.w, vertical: 4.h),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4.r)),
                              ),
                              style: TextStyle(fontSize: 12.w),
                              onChanged: (value) {
                                _sets[setIndex]['reps'] =
                                    int.tryParse(value) ?? 0;
                              },
                            ),
                          ),
                          SizedBox(width: 4.w),
                          // Load
                          SizedBox(
                            width: 60.w,
                            child: TextFormField(
                              initialValue: set['load'].toString(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4.w, vertical: 4.h),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4.r)),
                                suffixText: 'kg',
                                suffixStyle: TextStyle(fontSize: 10.w),
                              ),
                              style: TextStyle(fontSize: 12.w),
                              onChanged: (value) {
                                _sets[setIndex]['load'] =
                                    double.tryParse(value) ?? 0.0;
                              },
                            ),
                          ),
                          SizedBox(width: 4.w),
                          // RIR
                          SizedBox(
                            width: 50.w,
                            child: TextFormField(
                              initialValue: set['rir'].toString(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4.w, vertical: 4.h),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4.r)),
                              ),
                              style: TextStyle(fontSize: 12.w),
                              onChanged: (value) {
                                _sets[setIndex]['rir'] =
                                    int.tryParse(value) ?? 0;
                              },
                            ),
                          ),
                          SizedBox(width: 4.w),
                          // Completed checkbox
                          SizedBox(
                            width: 40.w,
                            child: Checkbox(
                              value: set['completed'],
                              onChanged: (value) {
                                setState(() {
                                  _sets[setIndex]['completed'] = value ?? false;
                                });
                              },
                              activeColor: AppTheme.primaryGold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  SizedBox(height: 12.h),

                  // Botón guardar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveLog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              height: 16.h,
                              width: 16.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Guardar Ejercicio',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.w,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
