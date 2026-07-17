import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User accessibility & settings configuration
class UserSettings {
  final bool wheelchairMode;
  final bool sensoryFriendlyMode;
  final String currentZone;
  final bool isDarkMode;

  const UserSettings({
    required this.wheelchairMode,
    required this.sensoryFriendlyMode,
    required this.currentZone,
    required this.isDarkMode,
  });

  UserSettings copyWith({
    bool? wheelchairMode,
    bool? sensoryFriendlyMode,
    String? currentZone,
    bool? isDarkMode,
  }) {
    return UserSettings(
      wheelchairMode: wheelchairMode ?? this.wheelchairMode,
      sensoryFriendlyMode: sensoryFriendlyMode ?? this.sensoryFriendlyMode,
      currentZone: currentZone ?? this.currentZone,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

/// StateNotifier that manages user configuration settings and saves them to local storage.
class SettingsNotifier extends StateNotifier<UserSettings> {
  SharedPreferences? _prefs;

  SettingsNotifier()
    : super(
        const UserSettings(
          wheelchairMode: false,
          sensoryFriendlyMode: false,
          currentZone: 'North',
          isDarkMode: false,
        ),
      ) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    final wc = _prefs?.getBool('wheelchairMode') ?? false;
    final sf = _prefs?.getBool('sensoryFriendlyMode') ?? false;
    final zone = _prefs?.getString('currentZone') ?? 'North';
    final dark = _prefs?.getBool('isDarkMode') ?? false;

    state = UserSettings(
      wheelchairMode: wc,
      sensoryFriendlyMode: sf,
      currentZone: zone,
      isDarkMode: dark,
    );
  }

  void toggleWheelchairMode() {
    final next = !state.wheelchairMode;
    state = state.copyWith(wheelchairMode: next);
    _prefs?.setBool('wheelchairMode', next);
  }

  void toggleSensoryFriendlyMode() {
    final next = !state.sensoryFriendlyMode;
    state = state.copyWith(sensoryFriendlyMode: next);
    _prefs?.setBool('sensoryFriendlyMode', next);
  }

  void toggleDarkMode() {
    final next = !state.isDarkMode;
    state = state.copyWith(isDarkMode: next);
    _prefs?.setBool('isDarkMode', next);
  }

  void setCurrentZone(String zone) {
    state = state.copyWith(currentZone: zone);
    _prefs?.setString('currentZone', zone);
  }
}

/// Global settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>((
  ref,
) {
  return SettingsNotifier();
});
