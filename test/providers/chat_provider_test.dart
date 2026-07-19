import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadium_genie/providers/chat_provider.dart';
import 'package:stadium_genie/models/message_model.dart';
import 'package:stadium_genie/providers/settings_provider.dart';
import 'package:stadium_genie/providers/auth_provider.dart';
import 'package:stadium_genie/repositories/ai_repository.dart';
import 'package:stadium_genie/repositories/stadium_repository.dart';
import 'package:stadium_genie/services/ai_service.dart';
import 'package:stadium_genie/services/mock_data_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(fileInput: 'AI_API_KEY=\n');
    SharedPreferences.setMockInitialValues({});
  });

  group('ChatNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          stadiumRepositoryProvider.overrideWithValue(
            StadiumRepositoryImpl(MockDataService()),
          ),
          aiRepositoryProvider.overrideWithValue(
            AIRepositoryImpl(AIService()),
          ),
          currentUserProvider.overrideWithValue(null),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has loading welcome message', () async {
      final notifier = container.read(chatProvider.notifier);
      // Wait for loadInitialData to complete
      await Future.delayed(const Duration(milliseconds: 300));

      final state = container.read(chatProvider);
      expect(state.isLoading, isFalse);
      expect(state.messages.isNotEmpty, isTrue);
      expect(state.messages.first.role, MessageRole.assistant);
      expect(state.messages.first.content, contains("Welcome"));
    });

    test('sendMessage sanitizes and adds user message and AI stream', () async {
      final notifier = container.read(chatProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 300));

      final future = notifier.sendMessage('Hello <tag>');
      
      final stateMid = container.read(chatProvider);
      // Sanity check that user and loading messages are appended
      expect(stateMid.messages.length, greaterThanOrEqualTo(2));
      expect(stateMid.messages.any((m) => m.content == 'Hello tag'), isTrue); // sanitized
      
      await future;

      final stateEnd = container.read(chatProvider);
      expect(stateEnd.isLoading, isFalse);
      expect(stateEnd.error, null);
    });

    test('sendMessage rate limiting rejects fast subsequent messages', () async {
      final notifier = container.read(chatProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 300));

      // Send first message and wait for it to finish
      await notifier.sendMessage('First query');
      
      // Try sending second message immediately after first finishes
      await notifier.sendMessage('Second query');

      final state = container.read(chatProvider);
      expect(state.error, contains("Please wait a moment"));
    });

    test('sendMessage long text validation error', () async {
      final notifier = container.read(chatProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 300));

      final longText = 'a' * 501;
      await notifier.sendMessage(longText);

      final state = container.read(chatProvider);
      expect(state.error, contains("Message is too long"));
    });

    test('clearChat resets messages list to initial state', () async {
      final notifier = container.read(chatProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 300));

      await notifier.sendMessage('Test clear');
      expect(container.read(chatProvider).messages.length, greaterThanOrEqualTo(2));

      notifier.clearChat();
      await Future.delayed(const Duration(milliseconds: 300));

      // Initial state has 1 message
      expect(container.read(chatProvider).messages.length, 1);
    });
  });
}
