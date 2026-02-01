// lib/providers/nutrition_navigation_provider.dart
import 'package:flutter/material.dart';

// Enum para definir las posibles sub-pantallas dentro de la pestaña de Nutrición.
enum NutritionSubPage { menu, plan, equivalentes, mediciones }

class NutritionNavigationProvider with ChangeNotifier {
  NutritionSubPage _currentPage = NutritionSubPage.menu;

  NutritionSubPage get currentPage => _currentPage;

  void goTo(NutritionSubPage page) {
    if (_currentPage == page) return;
    _currentPage = page;
    notifyListeners();
  }

  void backToMenu() {
    goTo(NutritionSubPage.menu);
  }
}
