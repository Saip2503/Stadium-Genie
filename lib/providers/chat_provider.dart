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

/// State of the chat interaction
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
      error: clearError ? null : error ?? this.error,
      stadiumData: stadiumData ?? this.stadiumData,
    );
  }
}

/// StateNotifier that manages chat messaging operations, mock IoT data loading,
/// and prompt building before requesting Gemini streaming answers.
class ChatNotifier extends StateNotifier<ChatState> {
  final StadiumRepository _stadiumRepository;
  final AIRepository _aiRepository;
  final Ref _ref;
  Timer? _updateTimer;
  DateTime? _lastMessageTime;

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
            suggestions: [
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

    // Sanitize input (basic)
    final sanitizedText = text.replaceAll(RegExp(r'[<>]'), '');

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

    // Append user message and loading assistant message
    state = state.copyWith(
      messages: [...state.messages, userMsg, loadingMsg],
      isLoading: true,
      clearError: true,
    );

    try {
      final settings = _ref.read(settingsProvider);

      // Ensure data is loaded
      StadiumData data;
      if (state.stadiumData != null) {
        data = state.stadiumData!;
      } else {
        data = await _stadiumRepository.getStadiumData();
        state = state.copyWith(stadiumData: data);
      }

      // Build contextual system instruction prompt
      final contextStr = _stadiumRepository.buildContextString(
        data: data,
        userZone: settings.currentZone,
        wheelchairMode: settings.wheelchairMode,
        sensoryMode: settings.sensoryFriendlyMode,
      );

      final systemPrompt =
          '''
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

      // Stream the assistant output
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

        // Update the last message in-place
        state = state.copyWith(
          messages: state.messages.map((m) {
            if (m.id == assistantMsgId) {
              return m.copyWith(content: cumulativeContent, isLoading: false);
            }
            return m;
          }).toList(),
        );
      }

      // Parse suggestions when done
      List<String> suggestions = [
        "What are the food options?",
        "Where is the merch store?",
        "Show transport options.",
      ];

      String finalContent = cumulativeContent;
      final suggestionIdx = cumulativeContent.indexOf("SUGGESTIONS:");
      if (suggestionIdx != -1) {
        final suggestionStr = cumulativeContent
            .substring(suggestionIdx + "SUGGESTIONS:".length)
            .trim();
        finalContent = cumulativeContent.substring(0, suggestionIdx).trim();
        suggestions = suggestionStr
            .split('|')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .take(3)
            .toList();
      }

      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.id == assistantMsgId) {
            return m.copyWith(content: finalContent, suggestions: suggestions);
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

/// Global chat provider
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final stadiumRepository = ref.read(stadiumRepositoryProvider);
  final aiRepository = ref.read(aiRepositoryProvider);
  return ChatNotifier(ref, stadiumRepository, aiRepository);
});
