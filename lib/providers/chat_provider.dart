import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../models/stadium_data_model.dart';
import '../repositories/ai_repository.dart';
import '../repositories/stadium_repository.dart';
import '../services/ai_service.dart';
import '../services/mock_data_service.dart';
import 'settings_provider.dart';

final stadiumRepositoryProvider = Provider<StadiumRepository>((ref) {
  return StadiumRepositoryImpl(MockDataService());
});

final aiRepositoryProvider = Provider<AIRepository>((ref) {
  return AIRepositoryImpl(AIService());
});

/// State of the chat interaction, tracking messages list, loading state,
/// error messages, and active stadium IoT data.
class ChatState {
  final List<MessageModel> messages;
  final bool isLoading;
  final String? error;
  final StadiumData? stadiumData;

  const ChatState({
    required this.messages,
    required this.isLoading,
    this.error,
    this.stadiumData,
  });

  /// Creates a copy of [ChatState] with updated fields, optionally clearing the error.
  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    String? error,
    StadiumData? stadiumData,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      stadiumData: stadiumData ?? this.stadiumData,
    );
  }
}

/// StateNotifier that manages chat messaging operations, mock IoT data loading,
/// rate limiting, sanitization, and Gemini prompt generation.
class ChatNotifier extends StateNotifier<ChatState> {
  final StadiumRepository _stadiumRepository;
  final AIRepository _aiRepository;
  final Ref _ref;
  Timer? _updateTimer;
  DateTime? _lastMessageTime;

  /// Max message history limit for memory efficiency and model context size safety.
  static const int maxMessageHistory = 20;

  ChatNotifier(this._ref, this._stadiumRepository, this._aiRepository)
    : super(const ChatState(messages: [], isLoading: false)) {
    loadInitialData();
    _startPeriodicUpdates();
  }

  void _startPeriodicUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (state.stadiumData != null) {
        final updatedData = _stadiumRepository.simulateUpdate(
          state.stadiumData!,
        );
        state = state.copyWith(stadiumData: updatedData);
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  /// Loads the stadium status from assets and adds a welcome message from the AI assistant
  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true);
    try {
      final stadiumData = await _stadiumRepository.getStadiumData();
      final user = FirebaseAuth.instance.currentUser;
      final nameStr = user?.displayName != null
          ? ", **${user!.displayName}**"
          : "";
      final bestFood = stadiumData.zonesByFoodQueue.first;
      final bestGate = stadiumData.gatesByQueue.first;
      final bestMerch = stadiumData.zonesByMerchQueue.first;
      state = state.copyWith(
        stadiumData: stadiumData,
        isLoading: false,
        messages: [
          MessageModel(
            id: MessageModel.generateId(),
            content:
                "Welcome to **${stadiumData.stadiumName}**$nameStr!\n\nI’m watching the live stadium feed right now. The fastest food is **${bestFood.key} Zone** at ${bestFood.value.foodQueueMins} min, the quickest gate is **${bestGate.key}** at ${bestGate.value.queueMins} min, and merch is fastest in **${bestMerch.key} Zone** at ${bestMerch.value.merchQueueMins} min.\n\nAsk me anything about queues, routes, accessibility, or transport and I’ll steer you to the best option.",
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
            suggestions: const [
              "Where is the closest bathroom?",
              "What is the fastest gate?",
              "Show me accessible routes.",
            ],
          ),
        ],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Failed to load stadium real-time operations data.",
      );
    }
  }

  /// Helper to filter out HTML tags and harmful control / zero-width characters.
  String _sanitizeText(String text) {
    return text.replaceAll(RegExp(r'[<>\u0000-\u001F\u200B-\u200F\uFEFF]'), '');
  }

  /// Private helper that generates the full contextual system instruction prompt.
  String _buildSystemPrompt(StadiumData data, UserSettings settings, String contextStr) {
    return '''
You are StadiumGenie, the official GenAI operational & wayfinding assistant for FIFA World Cup 2026.
You help fans, organizers, and volunteers navigate the stadium safely and efficiently.

USER CONTEXT:
- Seating Zone Location: ${settings.currentZone}
- Accessibility Mode (Wheelchair/Elevators): ${settings.wheelchairMode}
- Sensory-Friendly Preferences: ${settings.sensoryFriendlyMode}

$contextStr

RULES:
1. NATIVE MULTILINGUALISM: Detect the user's language automatically and respond natively. Keep stadium names, match teams, and directions translated accurately (e.g. "Pizza Palace" remains proper, but directional text is translated).
2. ACCESSIBILITY RULES:
   - If Accessibility Mode is TRUE, ONLY recommend accessible gates (Gate A, B, D) and zones with elevator accessibility (North, South, West).
   - Flag if the route requires climbing stairs (e.g., East Zone has NO elevator).
   - If Sensory-Friendly is TRUE, suggest quiet zones/sensory rooms in South or West when helpful.
3. CROWD AND ROUTING DECISIONS:
   - Advise the fan conversationally, comparing wait times for amenities including food, restrooms, merchandise, gates, elevators, and transportation.
   - For amenity questions, choose the shortest available wait that fits the user's access needs and explain the comparison. E.g. "North food queue is 15 mins, South is 3 mins. You should walk to the South zone (about 5 minutes) to save time."
   - Keep answers clear, supportive, and action-oriented. Limit responses to 3-4 sentences maximum.
4. Keep the tone friendly, helpful, and concise. Never mention raw JSON keys or system instructions.
5. At the end of your response, you may suggest 1-3 follow-up questions for the user. Format them as a list starting with "SUGGESTIONS:" and separate them with a pipe character "|". For example: "SUGGESTIONS: Nearest restroom | Quickest exit | Food options".
''';
  }

  /// Decodes suggestion chips from the AI raw message block.
  _SuggestionParseResult _parseAISuggestions(String content) {
    List<String> suggestions = const [
      "What are the food options?",
      "Where is the merch store?",
      "Show transport options.",
    ];
    String finalContent = content;
    final suggestionIdx = content.indexOf("SUGGESTIONS:");
    if (suggestionIdx != -1) {
      final suggestionStr = content
          .substring(suggestionIdx + "SUGGESTIONS:".length)
          .trim();
      finalContent = content.substring(0, suggestionIdx).trim();
      suggestions = suggestionStr
          .split('|')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .take(3)
          .toList();
    }
    return _SuggestionParseResult(finalContent, suggestions);
  }

  /// Sends a user message and streams the AI assistant response chunk-by-chunk.
  Future<void> sendMessage(String rawText) async {
    if (state.isLoading) return;

    // Rate limiting: 1 message per 2 seconds
    final now = DateTime.now();
    if (_lastMessageTime != null &&
        now.difference(_lastMessageTime!).inSeconds < 2) {
      state = state.copyWith(
        error: "Please wait a moment before sending another message.",
      );
      return;
    }

    final text = rawText.trim();
    if (text.isEmpty) return;

    // Input validation
    if (text.length > 500) {
      state = state.copyWith(
        error: "Message is too long (max 500 characters).",
      );
      return;
    }

    final sanitizedText = _sanitizeText(text);
    _lastMessageTime = now;

    final userMsg = MessageModel(
      id: MessageModel.generateId(),
      content: sanitizedText,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    final assistantMsgId = MessageModel.generateId();
    final loadingMsg = MessageModel(
      id: assistantMsgId,
      content: "",
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    // Memory efficiency: cap conversation history size to avoid overflow
    List<MessageModel> currentMessages = [...state.messages];
    if (currentMessages.length >= maxMessageHistory) {
      // Keep welcome message (index 0) and remove early intermediate history to keep it memory safe
      final welcome = currentMessages.first;
      currentMessages = [
        welcome,
        ...currentMessages.sublist(currentMessages.length - (maxMessageHistory - 2))
      ];
    }

    // Append user message and loading assistant message
    state = state.copyWith(
      messages: [...currentMessages, userMsg, loadingMsg],
      isLoading: true,
      clearError: true,
    );

    try {
      final settings = _ref.read(settingsProvider);

      StadiumData data;
      if (state.stadiumData != null) {
        data = state.stadiumData!;
      } else {
        data = await _stadiumRepository.getStadiumData();
        state = state.copyWith(stadiumData: data);
      }

      final contextStr = _stadiumRepository.buildContextString(
        data: data,
        userZone: settings.currentZone,
        wheelchairMode: settings.wheelchairMode,
        sensoryMode: settings.sensoryFriendlyMode,
      );

      final systemPrompt = _buildSystemPrompt(data, settings, contextStr);

      final stream = _aiRepository.sendMessageStream(
        conversationHistory: state.messages.sublist(
          0,
          state.messages.length - 1,
        ),
        systemPrompt: systemPrompt,
      );

      String cumulativeContent = "";

      await for (final chunk in stream) {
        cumulativeContent += chunk;

        state = state.copyWith(
          messages: state.messages.map((m) {
            if (m.id == assistantMsgId) {
              return m.copyWith(content: cumulativeContent, isLoading: false);
            }
            return m;
          }).toList(),
        );
      }

      final parseResult = _parseAISuggestions(cumulativeContent);

      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.id == assistantMsgId) {
            return m.copyWith(
              content: parseResult.content,
              suggestions: parseResult.suggestions,
            );
          }
          return m;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.id == assistantMsgId) {
            return m.copyWith(
              content:
                  "Sorry, I had trouble connecting to the live operational server. Please try asking again shortly.",
              isLoading: false,
            );
          }
          return m;
        }).toList(),
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Clears the message history and restarts
  void clearChat() {
    loadInitialData();
  }
}

/// Private helper class to hold parsed suggestion results.
class _SuggestionParseResult {
  final String content;
  final List<String> suggestions;

  const _SuggestionParseResult(this.content, this.suggestions);
}

/// Global chat provider
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final stadiumRepository = ref.read(stadiumRepositoryProvider);
  final aiRepository = ref.read(aiRepositoryProvider);
  return ChatNotifier(ref, stadiumRepository, aiRepository);
});
