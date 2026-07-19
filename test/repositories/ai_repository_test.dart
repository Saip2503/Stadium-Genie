import 'package:flutter_test/flutter_test.dart';
import 'package:stadium_genie/repositories/ai_repository.dart';
import 'package:stadium_genie/services/ai_service.dart';
import 'package:stadium_genie/models/message_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: 'AI_API_KEY=\n');
  });

  group('AIRepository Fallback Stream Tests', () {
    late AIRepository repository;

    setUp(() {
      repository = AIRepositoryImpl(AIService());
    });

    test('hasConfiguredApiKey is false without credentials', () {
      expect(repository.hasConfiguredApiKey, isFalse);
    });

    test('sendMessageStream yields non-empty string fallback tokens', () async {
      final userMessage = MessageModel(
        id: "test_msg",
        content: "Where is elevator in North?",
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );

      final stream = repository.sendMessageStream(
        conversationHistory: [userMessage],
        systemPrompt: "Seating: North\nAccessibility: true",
      );

      final chunks = await stream.toList();
      expect(chunks.isNotEmpty, isTrue);
      
      final fullText = chunks.join();
      expect(fullText, contains("elevator"));
    });
  });
}
