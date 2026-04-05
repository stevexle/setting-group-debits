import 'package:flutter/material.dart';

class TabNavigationState extends ChangeNotifier {
  int _currentIndex = 2; // Default to VÍ (Wallet) Tab

  int get currentIndex => _currentIndex;

  void setTab(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}
