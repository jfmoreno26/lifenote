import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local preferences: theme mode and whether alerts are enabled.
class SettingsService extends ChangeNotifier {
  SettingsService(this._prefs)
      : themeMode = ThemeMode.values[_prefs.getInt('themeMode') ?? ThemeMode.system.index],
        alertsEnabled = _prefs.getBool('alertsEnabled') ?? true;

  final SharedPreferences _prefs;
  ThemeMode themeMode;
  bool alertsEnabled;

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await _prefs.setInt('themeMode', mode.index);
  }

  Future<void> setAlertsEnabled(bool value) async {
    alertsEnabled = value;
    notifyListeners();
    await _prefs.setBool('alertsEnabled', value);
  }
}
