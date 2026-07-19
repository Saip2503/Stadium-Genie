import 'package:flutter_test/flutter_test.dart';
import 'package:stadium_genie/services/ai_service.dart';
import 'package:stadium_genie/models/message_model.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: 'AI_API_KEY=\n');
    dotenv.env.remove('AI_API_KEY');
    dotenv.env.remove('GEMINI_API_KEY');
    dotenv.env.remove('API_KEY');
  });

  group('AIService Fallback Tests', () {
    final aiService = AIService();

    test('hasConfiguredApiKey is false when not configured', () {
      expect(aiService.hasConfiguredApiKey, isFalse);
    });

    test('sendMessageStream with missing key yields mock fallback messages', () async {
      final userMessage = MessageModel(
        id: "1",
        content: "Where is food?",
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );

      final stream = aiService.sendMessageStream(
        conversationHistory: [userMessage],
        systemPrompt: "User Current Location: North\nAccessibility Mode: false",
      );

      final chunks = await stream.toList();
      final fullResponse = chunks.join();

      expect(fullResponse, contains("South Zone concessions"));
    });

    test('sendMessageStream handles bathroom query fallback', () async {
      final userMessage = MessageModel(
        id: "1",
        content: "I need restroom",
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );

      final stream = aiService.sendMessageStream(
        conversationHistory: [userMessage],
        systemPrompt: "User Current Location: North\nAccessibility Mode: false",
      );

      final chunks = await stream.toList();
      final fullResponse = chunks.join();

      expect(fullResponse, contains("North Zone restrooms"));
    });

    test('sendMessageStream handles accessibility query fallback', () async {
      final userMessage = MessageModel(
        id: "1",
        content: "wheelchair routes",
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );

      final stream = aiService.sendMessageStream(
        conversationHistory: [userMessage],
        systemPrompt: "User Current Location: East\nAccessibility Mode: true",
      );

      final chunks = await stream.toList();
      final fullResponse = chunks.join();

      expect(fullResponse, contains("Gate D"));
      expect(fullResponse, contains("elevator"));
    });
  });
}
