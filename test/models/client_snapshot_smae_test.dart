import 'package:flutter_test/flutter_test.dart';
import 'package:hefestocs/models/client.dart';
import 'package:hefestocs/models/client_snapshot.dart';

void main() {
  group('ClientSnapshot SMAE', () {
    test('detecta plan no configurado', () {
      final client = Client(
        id: 'c1',
        fullName: 'Paciente Demo',
        invitationCode: 'ABC123',
        kcalTarget: 2000,
        proteinG: 140,
        fatG: 70,
        carbG: 210,
        anthropometryHistory: const [],
        smaeEquivalentsByDay: const {},
        mealsPerDay: const {},
        smaeMealsByDay: const {},
      );

      final snapshot = ClientSnapshot(client: client);

      expect(snapshot.hasSmaePlan, isFalse);
      expect(snapshot.globalSmaeWarnings, isNotEmpty);
      expect(
        snapshot.globalSmaeWarnings.first,
        contains('Plan de equivalentes no configurado'),
      );
    });

    test('calcula kcal, delta y cobertura por día', () {
      final client = Client(
        id: 'c2',
        fullName: 'Paciente SMAE',
        invitationCode: 'DEF456',
        kcalTarget: 2000,
        proteinG: 150,
        fatG: 65,
        carbG: 220,
        anthropometryHistory: const [],
        smaeEquivalentsByDay: const {
          'monday': {
            'verduras': 6,
            'frutas': 4,
            'cereales_sin_grasa': 8,
            'aceites_sin_proteina': 4,
          },
        },
        mealsPerDay: const {
          'monday': 4,
        },
        smaeMealsByDay: const {
          'monday': {
            'breakfast': {'frutas': 2, 'cereales_sin_grasa': 3},
            'lunch': {'verduras': 3, 'cereales_sin_grasa': 3},
            'snack_pm': {'frutas': 2, 'aceites_sin_proteina': 1},
            'dinner': {'verduras': 3, 'aceites_sin_proteina': 3},
          },
        },
      );

      final snapshot = ClientSnapshot(client: client);

      final kcal = snapshot.calculatedKcalForDay('monday');
      final delta = snapshot.kcalDeltaForDay('monday');
      final coverage = snapshot.coveragePercentForDay('monday');

      expect(kcal, closeTo(1130, 0.01));
      expect(delta, closeTo(-870, 0.01));
      expect(coverage, closeTo(56.5, 0.01));
      expect(snapshot.coverageLevelForDay('monday'), equals('red'));
      expect(snapshot.planWarningsForDay('monday').join(' '),
          contains('Delta kcal alto'));
    });
  });
}
