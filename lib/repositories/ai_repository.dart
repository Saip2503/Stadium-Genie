import '../models/message_model.dart';
import '../services/ai_service.dart';

/// Repository interface facilitating streaming communication with Gemini generative models
/// and configuration status verification.
abstract class AIRepository {
  /// Sends a conversation history block and streams back text chunk tokens.
  Stream<String> sendMessageStream({
    required List<MessageModel> conversationHistory,
    required String systemPrompt,
  });

  /// Flags if a valid generative AI API credentials key is active.
  bool get hasConfiguredApiKey;
}

/// Concrete implementation of [AIRepository] delegating requests to [AIService].
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
