import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadium_genie/providers/chat_provider.dart';
import 'package:stadium_genie/models/message_model.dart';
import 'package:stadium_genie/providers/settings_provider.dart';
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
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has loading welcome message', () async {
      final notifier = container.read(chatProvider.notifier);
      // Wait for loadInitialData to complete
      await Future.delayed(const Duration(milliseconds: 150));

      final state = container.read(chatProvider);
      expect(state.isLoading, isFalse);
      expect(state.messages.isNotEmpty, isTrue);
      expect(state.messages.first.role, MessageRole.assistant);
      expect(state.messages.first.content, contains("Welcome"));
    });

    test('sendMessage sanitizes and adds user message and AI stream', () async {
      final notifier = container.read(chatProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 150));

      final future = notifier.sendMessage('Hello <tag>');
      
      final stateMid = container.read(chatProvider);
      // Sanity check that user and loading messages are appended
      expect(stateMid.messages.length, greaterThanOrEqualTo(2));
      expect(stateMid.messages[1].content, 'Hello tag'); // sanitized
      expect(stateMid.messages[1].role, MessageRole.user);
      expect(stateMid.messages[2].role, MessageRole.assistant);

      await future;

      final stateEnd = container.read(chatProvider);
      expect(stateEnd.isLoading, isFalse);
      expect(stateEnd.error, null);
    });

    test('sendMessage rate limiting rejects fast subsequent messages', () async {
      final notifier = container.read(chatProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 150));

      // Send first message
      final f1 = notifier.sendMessage('First query');
      
      // Try sending second message immediately
      await notifier.sendMessage('Second query');

      final state = container.read(chatProvider);
      expect(state.error, contains("Please wait a moment"));

      await f1;
    });

    test('sendMessage long text validation error', () async {
      final notifier = container.read(chatProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 150));

      final longText = 'a' * 501;
      await notifier.sendMessage(longText);

      final state = container.read(chatProvider);
      expect(state.error, contains("Message is too long"));
    });

    test('clearChat resets messages list to initial state', () async {
      final notifier = container.read(chatProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 150));

      await notifier.sendMessage('Test clear');
      expect(container.read(chatProvider).messages.length, greaterThanOrEqualTo(2));

      notifier.clearChat();
      await Future.delayed(const Duration(milliseconds: 150));

      expect(container.read(chatProvider).messages.length, 1);
    });
  });
}
