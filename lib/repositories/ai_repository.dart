import '../models/message_model.dart';
import '../services/ai_service.dart';

abstract class AIRepository {
  Stream<String> sendMessageStream({
    required List<MessageModel> conversationHistory,
    required String systemPrompt,
  });
  bool get hasConfiguredApiKey;
}

class AIRepositoryImpl implements AIRepository {
  final AIService _aiService;

  AIRepositoryImpl(this._aiService);

  @override
  Stream<String> sendMessageStream({
    required List<MessageModel> conversationHistory,
    required String systemPrompt,
  }) {
    return _aiService.sendMessageStream(
      conversationHistory: conversationHistory,
      systemPrompt: systemPrompt,
    );
  }

  @override
  bool get hasConfiguredApiKey => _aiService.hasConfiguredApiKey;
}
