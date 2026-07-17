/// Message roles in the chat conversation
enum MessageRole { user, assistant, system }

/// Represents a single message in the chat conversation
class MessageModel {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isLoading;

  const MessageModel({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isLoading = false,
  });

  MessageModel copyWith({
    String? id,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return MessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;

  /// Generates a unique ID for a new message
  static String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();
}
