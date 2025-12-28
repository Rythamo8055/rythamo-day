import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:journal_app/theme/rythamo_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_provider.g.dart';

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  RythamoThemeMode build() {
    // Load saved theme asynchronously
    _loadSavedTheme();
    return RythamoThemeMode.mocha; // Default until loaded
  }

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('theme_mode');
    if (savedIndex != null && savedIndex < RythamoThemeMode.values.length) {
      state = RythamoThemeMode.values[savedIndex];
    }
  }

  void setMode(RythamoThemeMode mode) {
    state = mode;
    _saveTheme(mode);
  }

  Future<void> _saveTheme(RythamoThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }
  
  void toggleMode() {
    // Cycle through modes: Mocha -> Latte -> Frappe -> Macchiato -> Mocha
    RythamoThemeMode newMode;
    switch (state) {
      case RythamoThemeMode.mocha:
        newMode = RythamoThemeMode.latte;
        break;
      case RythamoThemeMode.latte:
        newMode = RythamoThemeMode.frappe;
        break;
      case RythamoThemeMode.frappe:
        newMode = RythamoThemeMode.macchiato;
        break;
      case RythamoThemeMode.macchiato:
        newMode = RythamoThemeMode.mocha;
        break;
    }
    setMode(newMode); // Use setMode to persist
  }
}

