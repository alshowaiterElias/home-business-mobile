import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/network/storage_service.dart';

class ThemeController extends GetxController {
  static const String _themeKey = 'app_theme_mode';
  final themeMode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  void _loadTheme() {
    final saved = StorageService.getString(_themeKey);
    if (saved == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else if (saved == 'light') {
      themeMode.value = ThemeMode.light;
    } else {
      themeMode.value = ThemeMode.system;
    }
  }

  bool get isDarkMode {
    if (themeMode.value == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return themeMode.value == ThemeMode.dark;
  }

  void setTheme(ThemeMode mode) {
    themeMode.value = mode;
    StorageService.setString(_themeKey, mode.name);
    Get.changeThemeMode(mode);
  }

  void toggleTheme() {
    setTheme(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }
}
