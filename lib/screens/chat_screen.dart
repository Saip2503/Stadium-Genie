import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/side_nav_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/accessibility_wrapper.dart';

/// Conversation chat interface with StadiumGenie.
/// Implements contextual system prompt injecting current location and accessibility options.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestedPrompts = [
    "Find the shortest restroom queue",
    "Find food with the lowest wait",
    "Find merch near me",
    "Emergency and first aid info",
    "Wheelchair accessible route to concessions",
    "Find a sensory friendly quiet zone",
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(String text) async {
    if (text.trim().isEmpty) return;
    _messageController.clear();
    await ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = settings.isDarkMode;

    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width >= 900;

    // Trigger scrolling when messages change or loading begins
    _scrollToBottom();

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.bolt, color: AppColors.primaryContainer),
            const SizedBox(width: 8),
            Text(
              "StadiumGenie AI assistant",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getOnSurface(isDark),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.getSurface(isDark),
        elevation: 0,
        actions: [
          // Clear Conversation history option
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: "Reset conversation history",
            onPressed: () {
              ref.read(chatProvider.notifier).clearChat();
            },
          ),
        ],
        iconTheme: IconThemeData(color: AppColors.getOnSurface(isDark)),
        shape: Border(
          bottom: BorderSide(
            color: AppColors.getOutline(isDark).withValues(alpha: 0.15),
          ),
        ),
      ),
      body: Row(
        children: [
          // Desktop sidebar nav
          if (isDesktop)
            SideNavBar(
              activeRoute: '/chat',
              isDark: isDark,
              onNavigate: (route) =>
                  Navigator.pushReplacementNamed(context, route),
            ),

          // Main conversation panel
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  // Location and Accessibility Context indicator bar at top of chat pane
                  _buildContextIndicatorBar(settings, isDark),
                  if (chatState.error != null)
                    _buildErrorBanner(chatState.error!, isDark),

                  // Message list view
                  Expanded(
                    child: chatState.messages.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: chatState.messages.length,
                            itemBuilder: (context, index) {
                              final msg = chatState.messages[index];
                              return ChatBubble(message: msg, isDark: isDark);
                            },
                          ),
                  ),

                  // Suggested prompts quick click chips list
                  if (chatState.messages.length <= 1)
                    _buildSuggestedChips(isDark),

                  // Input controls panel
                  _buildInputPanel(chatState.isLoading, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? BottomNavBar(
              activeRoute: '/chat',
              isDark: isDark,
              onNavigate: (route) =>
                  Navigator.pushReplacementNamed(context, route),
            )
          : null,
    );
  }

  Widget _buildContextIndicatorBar(UserSettings settings, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceContainer(isDark).withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: AppColors.getOutline(isDark).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Seating location label
          _buildContextBadge(
            icon: Icons.location_on,
            label: "Zone: ${settings.currentZone}",
            isDark: isDark,
          ),
          // Wheelchair mode active label
          if (settings.wheelchairMode)
            _buildContextBadge(
              icon: Icons.accessible,
              label: "Wheelchair routes filtering",
              color: AppColors.primaryContainer,
              isDark: isDark,
            ),
          // Quiet zone sensory active label
          if (settings.sensoryFriendlyMode)
            _buildContextBadge(
              icon: Icons.volume_mute,
              label: "Sensory friendly mode",
              color: AppColors.secondary,
              isDark: isDark,
            ),
          // Translation note
          _buildContextBadge(
            icon: Icons.translate,
            label: "Auto translating",
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildContextBadge({
    required IconData icon,
    required String label,
    required bool isDark,
    Color? color,
  }) {
    final activeColor = color ?? AppColors.getOnSurfaceVariant(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: activeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: activeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedChips(bool isDark) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestedPrompts.length,
        itemBuilder: (context, index) {
          final prompt = _suggestedPrompts[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: AccessibilityWrapper(
              label: "Suggested question: $prompt",
              isButton: true,
              child: ActionChip(
                backgroundColor: AppColors.getSurfaceContainer(isDark),
                label: Text(
                  prompt,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getOnSurface(isDark),
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppColors.getOutline(isDark).withValues(alpha: 0.15),
                  ),
                ),
                onPressed: () => _handleSend(prompt),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorBanner(String message, bool isDark) {
    return Semantics(
      label: 'AI setup warning: $message',
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppColors.tertiaryContainer.withValues(
          alpha: isDark ? 0.35 : 0.12,
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: isDark ? Colors.white : AppColors.tertiary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: isDark ? Colors.white : AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputPanel(bool isLoading, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        border: Border(
          top: BorderSide(
            color: AppColors.getOutline(isDark).withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          // Chat input field
          Expanded(
            child: AccessibilityWrapper(
              label: "Message input text field",
              hint: "Type your query here",
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: _handleSend,
                decoration: InputDecoration(
                  hintText: "Type message in any language...",
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: AppColors.getOnSurfaceVariant(
                      isDark,
                    ).withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: AppColors.getSurfaceContainerHigh(isDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(color: AppColors.getOnSurface(isDark)),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Send message action button
          AccessibilityWrapper(
            label: "Send message button",
            hint: "Tap to ask the AI assistant",
            isButton: true,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryContainer,
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => _handleSend(_messageController.text),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
