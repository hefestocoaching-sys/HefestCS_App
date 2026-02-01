// lib/providers/training_navigation_provider.dart
import 'package:flutter/material.dart';

// Enum para definir las posibles sub-pantallas dentro de la pestaña de Entrenamiento.
enum TrainingSubPage { menu, plan, log, photos }

class TrainingNavigationProvider with ChangeNotifier {
  TrainingSubPage _currentPage = TrainingSubPage.menu;

  TrainingSubPage get currentPage => _currentPage;

  // Método para navegar a una sub-pantalla específica.
  void goTo(TrainingSubPage page) {
    if (_currentPage == page) return; // No hace nada si ya está en esa página
    _currentPage = page;
    notifyListeners();
  }

  // Método para volver al menú principal de la pestaña.
  void backToMenu() {
    goTo(TrainingSubPage.menu);
  }
}
