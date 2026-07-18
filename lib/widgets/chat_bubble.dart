import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/message_model.dart';
import '../theme/app_colors.dart';
import 'accessibility_wrapper.dart';

/// Renders a chat message bubble following corporate modern and glassmorphic designs
class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isDark;
  final ValueChanged<String>? onSuggestionTap;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isDark,
    this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    final userBg = const LinearGradient(
      colors: [AppColors.primary, AppColors.primaryContainer],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final aiBg = AppColors.getSurfaceContainer(isDark);
    final textStyle = TextStyle(
      fontSize: 16,
      height: 1.5,
      color: isUser ? Colors.white : AppColors.getOnSurface(isDark),
    );

    return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Sender name & time metadata
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
                  child: Text(
                    isUser ? "You" : "StadiumGenie AI",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getOnSurfaceVariant(
                        isDark,
                      ).withValues(alpha: 0.8),
                    ),
                  ),
                ),

                // Interactive bubble
                GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: message.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: AccessibilityWrapper(
                    label:
                        "${isUser ? 'User message' : 'AI Assistant response'}: ${message.content}",
                    hint: "Long press to copy text",
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isUser ? userBg : null,
                        color: isUser ? null : aiBg,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isUser
                              ? const Radius.circular(16)
                              : const Radius.circular(4),
                          bottomRight: isUser
                              ? const Radius.circular(4)
                              : const Radius.circular(16),
                        ),
                        border: isDark && !isUser
                            ? Border.all(
                                color: AppColors.darkOutlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.05,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            // Left accent vertical line for AI assistant response
                            if (!isUser)
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: 4,
                                child: Container(
                                  color: AppColors.primaryContainer,
                                ),
                              ),

                            Padding(
                              padding: EdgeInsets.only(
                                left: !isUser ? 20.0 : 16.0,
                                right: 16.0,
                                top: 12.0,
                                bottom: 12.0,
                              ),
                              child: message.isLoading
                                  ? _buildTypingIndicator(isDark)
                                  : Text(message.content, style: textStyle),
                            ),
                            if (message.isAssistant &&
                                message.suggestions.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: message.suggestions.map((suggestion) {
                                  return AccessibilityWrapper(
                                    label: 'Suggested follow-up: $suggestion',
                                    isButton: true,
                                    child: ActionChip(
                                      onPressed: onSuggestionTap == null
                                          ? null
                                          : () => onSuggestionTap!(suggestion),
                                      backgroundColor:
                                          AppColors.getSurfaceContainer(isDark),
                                      side: BorderSide(
                                        color: AppColors.getOutline(
                                          isDark,
                                        ).withValues(alpha: 0.2),
                                      ),
                                      label: Text(
                                        suggestion,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.getOnSurface(isDark),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fade(duration: 200.ms)
        .slideX(begin: isUser ? 0.05 : -0.05, duration: 200.ms);
  }

  Widget _buildTypingIndicator(bool isDark) {
    final dotColor = AppColors.getOnSurfaceVariant(isDark);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .scale(
              begin: const Offset(0.6, 0.6),
              end: const Offset(1.2, 1.2),
              duration: 600.ms,
              curve: Curves.easeInOut,
              delay: (index * 200).ms,
            )
            .then()
            .scale(
              begin: const Offset(1.2, 1.2),
              end: const Offset(0.6, 0.6),
              duration: 600.ms,
              curve: Curves.easeInOut,
            );
      }),
    );
  }
}
