// lib/providers/charts_navigation_provider.dart
import 'package:flutter/material.dart';

// Enum para definir las posibles sub-pantallas dentro de la pestaña de Gráficas.
enum ChartsSubPage { menu, measurements, training }

class ChartsNavigationProvider with ChangeNotifier {
  ChartsSubPage _currentPage = ChartsSubPage.menu;

  ChartsSubPage get currentPage => _currentPage;

  void goTo(ChartsSubPage page) {
    if (_currentPage == page) return;
    _currentPage = page;
    notifyListeners();
  }

  void backToMenu() {
    goTo(ChartsSubPage.menu);
  }
}
