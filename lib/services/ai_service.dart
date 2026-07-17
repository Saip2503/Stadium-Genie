import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/message_model.dart';

/// Service that interacts with Google Gemini API to get context-aware,
/// multilingual, and accessible recommendations for fans.
class AIService {
  GenerativeModel? _model;
  String? _initializedApiKey;
  String? _initializedSystemPrompt;

  static const missingApiKeyMessage =
      "AI setup needed: add a .env file at the project root with AI_API_KEY=your_gemini_api_key. The app will keep running with simulated stadium guidance until a key is provided.";

  String _readApiKey() {
    return (dotenv.env['AI_API_KEY'] ??
            dotenv.env['GEMINI_API_KEY'] ??
            dotenv.env['API_KEY'] ??
            '')
        .trim();
  }

  bool get hasConfiguredApiKey => _readApiKey().isNotEmpty;

  /// Initializes the Gemini generative model.
  /// If the model is already initialized with the current API key and system prompt, it is reused.
  void _initModel(String systemPrompt) {
    final apiKey = _readApiKey();

    if (apiKey.isEmpty) {
      // If no valid key is provided, we will handle it gracefully in the service call.
      _model = null;
      return;
    }

    if (_model != null &&
        _initializedApiKey == apiKey &&
        _initializedSystemPrompt == systemPrompt) {
      return;
    }

    _initializedApiKey = apiKey;
    _initializedSystemPrompt = systemPrompt;
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(systemPrompt),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
      ],
    );
  }

  /// Sends a conversation message list to the Gemini API and yields the response chunk by chunk.
  /// If the API key is missing or invalid, it returns a simulated offline response using mock rules.
  Stream<String> sendMessageStream({
    required List<MessageModel> conversationHistory,
    required String systemPrompt,
  }) async* {
    _initModel(systemPrompt);

    if (_model == null) {
      // Fallback: Generate a smart simulated response locally if API key is missing.
      yield "$missingApiKeyMessage\n\n";
      yield* _generateMockFallbackResponse(
        conversationHistory.last.content,
        systemPrompt,
      );
      return;
    }

    try {
      // Convert message history to Content objects for Gemini API
      final contents = conversationHistory.map((msg) {
        if (msg.role == MessageRole.user) {
          return Content.text(msg.content);
        } else if (msg.role == MessageRole.assistant) {
          return Content.model([TextPart(msg.content)]);
        } else {
          return Content.system(msg.content);
        }
      }).toList();

      final responseStream = _model!.generateContentStream(contents);

      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      // Return error message and fallback response stream
      yield "Connection error from Gemini. Here is a simulated helper response:\n\n";
      yield* _generateMockFallbackResponse(
        conversationHistory.last.content,
        systemPrompt,
      );
    }
  }

  /// Generates a mock conversational response based on simple rules matching keywords and context,
  /// keeping the app fully functional and interactive even without a valid API key.
  Stream<String> _generateMockFallbackResponse(
    String userMessage,
    String systemPrompt,
  ) async* {
    final msgLower = userMessage.toLowerCase();

    // Parse settings mode from prompt string
    final wheelchairMode = systemPrompt.contains('Accessibility Mode: true');
    final currentZone =
        RegExp(
          r'User Current Location:\s*(\w+)',
        ).firstMatch(systemPrompt)?.group(1) ??
        'North';

    // Simulate thinking delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (msgLower.contains('hungry') ||
        msgLower.contains('food') ||
        msgLower.contains('eat') ||
        msgLower.contains('comida')) {
      if (wheelchairMode) {
        yield "Since you have wheelchair accessibility active, I recommend the **South Zone** concessions (like Sushi Station or Wrap World). They have elevator access, a short 3-minute queue, and accessible paths. The walk from the $currentZone Zone is about 4-5 minutes using the elevator route.";
      } else {
        yield "Current stadium data shows the South Zone concessions have only a 3-minute queue, while your current zone ($currentZone Zone) has a 15-minute food queue. I highly recommend heading to the **South Zone** concessions. It's a quick 5-minute walk!";
      }
    } else if (msgLower.contains('merch') ||
        msgLower.contains('souvenir') ||
        msgLower.contains('jersey') ||
        msgLower.contains('store')) {
      yield "For merchandise, head to the **South Zone** shop first: the current merch wait is 4 minutes, compared with 12 minutes in North and 18 minutes in East. From the $currentZone Zone, follow the concourse signs toward South and you should save several minutes.";
    } else if (msgLower.contains('bathroom') ||
        msgLower.contains('restroom') ||
        msgLower.contains('toilet') ||
        msgLower.contains('baño')) {
      if (currentZone == 'North') {
        yield "You're in luck! The **North Zone restrooms** currently have a very short queue of only 2 minutes. The closest restroom is located near Section 102. Feel free to head there directly.";
      } else {
        yield "Restroom queue times: North Zone is 2 minutes, West Zone is 3 minutes. Since you are in the $currentZone Zone, the closest restrooms with short wait times are in the **West Zone**. Avoid the South Zone restrooms as they currently have a 10-minute wait.";
      }
    } else if (msgLower.contains('accessible') ||
        msgLower.contains('wheelchair') ||
        msgLower.contains('elevator') ||
        msgLower.contains('rampa')) {
      yield "MetLife Stadium accessibility features for World Cup 2026: Elevators are located in the **North**, **South**, and **West** Zones. **Gate D** is the dedicated accessible gate with flat terrain and direct shuttle access. East Zone does not have wheelchair elevators; please follow the marked accessible path towards the North or West corridors.";
    } else if (msgLower.contains('quiet') ||
        msgLower.contains('sensory') ||
        msgLower.contains('calm') ||
        msgLower.contains('ruido')) {
      yield "Sensory-friendly quiet rooms are available for fans who need a calm space. You can find them in the **South Zone (Level 2)** and **West Zone (Level 1)**. These zones offer noise-canceling headphones, sensory bags, and trained volunteer staff to assist you.";
    } else if (msgLower.contains('gate') ||
        msgLower.contains('entrance') ||
        msgLower.contains('entrada') ||
        msgLower.contains('exit')) {
      yield "Gate status updates: Gate B (South) has a 5-minute queue. Gate D (West) has a 2-minute queue. Gate A (North) is very crowded with a 25-minute queue. If you are leaving or arriving, please use **Gate D** or **Gate B** for a faster entry/exit.";
    } else if (msgLower.contains('emergency') ||
        msgLower.contains('first aid') ||
        msgLower.contains('medical') ||
        msgLower.contains('help')) {
      yield "For urgent help, go to the nearest staffed first-aid point: **Section 102 in North**, **Section 203 in South**, or **Section 402 in West**. Guest Services is at **Section 104, North Zone Concourse**. If this is a medical emergency, notify stadium staff immediately.";
    } else if (msgLower.contains('bus') ||
        msgLower.contains('train') ||
        msgLower.contains('subway') ||
        msgLower.contains('parking') ||
        msgLower.contains('metro')) {
      yield "Transport options: The NJ Transit Meadowlands Rail subway train has next arrivals in 5, 22, and 38 minutes with moderate crowding. Bus routes 350, 351, and 352 have high crowding and depart in 8 minutes. Parking Lot A has 120 available spots left (including 15 accessible).";
    } else {
      // Multilingual hello fallback
      if (msgLower.contains('hola') ||
          msgLower.contains('como') ||
          msgLower.contains('buenos')) {
        yield "¡Hola! Soy StadiumGenie, tu asistente de la Copa Mundial de la FIFA 2026. Te puedo ayudar a encontrar comida, baños sin fila, rutas accesibles en silla de ruedas o transporte. ¿Qué necesitas en este momento?";
      } else if (msgLower.contains('bonjour') || msgLower.contains('salut')) {
        yield "Bonjour! Je suis StadiumGenie, votre assistant de la Coupe du Monde de la FIFA 2026. Comment puis-je vous aider aujourd'hui? (restauration, accessibilité, itinéraires sans file d'attente)";
      } else {
        yield "Welcome to FIFA World Cup 2026! I am StadiumGenie. I can guide you through the stadium using real-time data. You can ask me questions like: 'Where is the shortest restroom queue?', 'How do I find wheelchair accessible paths?', or 'What is the fastest way to the subway?'";
      }
    }
  }
}
