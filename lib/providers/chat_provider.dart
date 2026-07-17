import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../models/stadium_data_model.dart';
import '../services/ai_service.dart';
import '../services/mock_data_service.dart';
import 'settings_provider.dart';

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
  final AIService _aiService = AIService();
  final MockDataService _mockDataService = MockDataService();
  final Ref _ref;

  ChatNotifier(this._ref)
    : super(const ChatState(messages: [], isLoading: false)) {
    loadInitialData();
  }

  /// Loads the stadium status from assets and adds a welcome message from the AI assistant
  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true);
    try {
      final stadiumData = await _mockDataService.loadStadiumData();
      final user = FirebaseAuth.instance.currentUser;
      final nameStr = user?.displayName != null
          ? ", **${user!.displayName}**"
          : "";
      state = state.copyWith(
        stadiumData: stadiumData,
        isLoading: false,
        messages: [
          MessageModel(
            id: MessageModel.generateId(),
            content:
                "🏟️ Welcome to **${stadiumData.stadiumName}**$nameStr!\n\nI am **StadiumGenie**, your FIFA World Cup 2026 AI Assistant. I have live crowd details for concession queues, gates, elevators, and transportation.\n\nAsk me anything! For example: *'Where is the closest bathroom with no line?'* or *'Are there wheelchair elevators near me?'*",
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
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
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isLoading) return;

    final userMsg = MessageModel(
      id: MessageModel.generateId(),
      content: text,
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
      error: _aiService.hasConfiguredApiKey
          ? null
          : AIService.missingApiKeyMessage,
      clearError: _aiService.hasConfiguredApiKey,
    );

    try {
      final settings = _ref.read(settingsProvider);

      // Ensure data is loaded
      StadiumData data;
      if (state.stadiumData != null) {
        data = state.stadiumData!;
      } else {
        data = await _mockDataService.loadStadiumData();
        state = state.copyWith(stadiumData: data);
      }

      // Build contextual system instruction prompt
      final contextStr = _mockDataService.buildContextString(
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
''';

      // Stream the assistant output
      final stream = _aiService.sendMessageStream(
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
  return ChatNotifier(ref);
});
