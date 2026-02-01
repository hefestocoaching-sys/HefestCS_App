import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum ShortcutType {
  planEntrenamiento,
  bitacora,
  fotos,
  planNutricion,
  equivalentes,
  mediciones,
}

class Shortcut {
  final ShortcutType type;
  final String title;
  final IconData icon;

  Shortcut({required this.type, required this.title, required this.icon});
}

class SettingsProvider with ChangeNotifier {
  final List<Shortcut> _allShortcuts = [
    Shortcut(type: ShortcutType.planEntrenamiento, title: 'Plan de Hoy', icon: Icons.calendar_today_outlined),
    Shortcut(type: ShortcutType.bitacora, title: 'Bitácora', icon: FontAwesomeIcons.book),
    Shortcut(type: ShortcutType.fotos, title: 'Fotos', icon: Icons.camera_alt_outlined),
    Shortcut(type: ShortcutType.planNutricion, title: 'Plan Alimenticio', icon: Icons.restaurant_menu),
    Shortcut(type: ShortcutType.equivalentes, title: 'Equivalentes', icon: Icons.swap_horiz),
    Shortcut(type: ShortcutType.mediciones, title: 'Mediciones', icon: Icons.straighten),
  ];

  final List<ShortcutType> _selectedShortcutTypes = [
    ShortcutType.planEntrenamiento,
    ShortcutType.fotos,
    ShortcutType.planNutricion,
  ];

  List<Shortcut> get allShortcuts => _allShortcuts;
  List<ShortcutType> get selectedShortcutTypes => _selectedShortcutTypes;

  List<Shortcut> get orderedSelectedShortcuts {
    return _selectedShortcutTypes.map((type) {
      return _allShortcuts.firstWhere((s) => s.type == type);
    }).toList();
  }

  void toggleShortcut(ShortcutType type) {
    final isSelected = _selectedShortcutTypes.contains(type);

    if (isSelected) {
      if (_selectedShortcutTypes.length > 1) {
        _selectedShortcutTypes.remove(type);
        notifyListeners();
      }
    } else {
      if (_selectedShortcutTypes.length < 3) {
        _selectedShortcutTypes.add(type);
        notifyListeners();
      }
    }
  }

  void reorderShortcuts(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _selectedShortcutTypes.removeAt(oldIndex);
    _selectedShortcutTypes.insert(newIndex, item);
    notifyListeners();
  }
}