import 'package:flutter/material.dart';

class NavigatorKeys {
  final GlobalKey<NavigatorState> home;
  final GlobalKey<NavigatorState> nutrition;
  final GlobalKey<NavigatorState> training;
  final GlobalKey<NavigatorState> charts;
  final GlobalKey<NavigatorState> biochem;

  NavigatorKeys({
    required this.home,
    required this.nutrition,
    required this.training,
    required this.charts,
    required this.biochem,
  });
}