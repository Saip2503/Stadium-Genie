import '../models/message_model.dart';
import '../services/ai_service.dart';

abstract class AIRepository {
  bool get hasConfiguredApiKey;

  Stream<String> sendMessageStream({
    required List<MessageModel> conversationHistory,
    required String systemPrompt,
  });
}

class AIRepositoryImpl implements AIRepository {
  final AIService _service;

  AIRepositoryImpl(this._service);

  @override
  bool get hasConfiguredApiKey => _service.hasConfiguredApiKey;

  @override
  Stream<String> sendMessageStream({
    required List<MessageModel> conversationHistory,
    required String systemPrompt,
  }) {
    return _service.sendMessageStream(
      conversationHistory: conversationHistory,
      systemPrompt: systemPrompt,
    );
  }
}
