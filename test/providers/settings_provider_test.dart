import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stadium_genie/providers/settings_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsNotifier Tests', () {
    test('Initializes with default values', () async {
      final notifier = SettingsNotifier();
      // Allow async shared preferences initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));

      expect(notifier.state.wheelchairMode, isFalse);
      expect(notifier.state.sensoryFriendlyMode, isFalse);
      expect(notifier.state.currentZone, equals('North'));
      expect(notifier.state.isDarkMode, isFalse);
    });

    test('Toggles wheelchair mode', () async {
      final notifier = SettingsNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      notifier.toggleWheelchairMode();
      expect(notifier.state.wheelchairMode, isTrue);

      notifier.toggleWheelchairMode();
      expect(notifier.state.wheelchairMode, isFalse);
    });

    test('Toggles sensory friendly mode', () async {
      final notifier = SettingsNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      notifier.toggleSensoryFriendlyMode();
      expect(notifier.state.sensoryFriendlyMode, isTrue);
    });

    test('Toggles dark mode', () async {
      final notifier = SettingsNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      notifier.toggleDarkMode();
      expect(notifier.state.isDarkMode, isTrue);
    });

    test('Sets current zone', () async {
      final notifier = SettingsNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      notifier.setCurrentZone('West');
      expect(notifier.state.currentZone, equals('West'));
    });
  });
}
