/// Message roles in the chat conversation
enum MessageRole { user, assistant, system }

/// Message categories for richer rendering
enum MessageType { text, suggestion, alert, emergency }

/// Represents a single message in the chat conversation
class MessageModel {
  final String id;
  final String content;
  final MessageRole role;
  final MessageType type;
  final DateTime timestamp;
  final bool isLoading;
  final List<String> suggestions;
  final bool isError;

  const MessageModel({
    required this.id,
    required this.content,
    required this.role,
    this.type = MessageType.text,
    required this.timestamp,
    this.isLoading = false,
    this.suggestions = const [],
    this.isError = false,
  });

  MessageModel copyWith({
    String? id,
    String? content,
    MessageRole? role,
    MessageType? type,
    DateTime? timestamp,
    bool? isLoading,
    List<String>? suggestions,
    bool? isError,
  }) {
    return MessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      suggestions: suggestions ?? this.suggestions,
      isError: isError ?? this.isError,
    );
  }

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;

  /// Generates a unique ID for a new message
  static String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();
}
