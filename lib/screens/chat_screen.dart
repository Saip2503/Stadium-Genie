import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  bool _hideApiKeyBanner = false;

  final List<Map<String, dynamic>> _suggestedPrompts = [
    {
      'icon': Icons.wc,
      'label': 'Nearest restroom',
      'query': 'Find the nearest restroom with shortest queue from my zone',
    },
    {
      'icon': Icons.fastfood,
      'label': 'Fastest food line',
      'query': 'Which food stand has the shortest wait near me right now?',
    },
    {
      'icon': Icons.storefront,
      'label': 'Find merch nearby',
      'query': 'Find a merchandise stand close to my current zone',
    },
    {
      'icon': Icons.local_hospital,
      'label': 'Emergency & First Aid',
      'query': 'Where is the nearest emergency first aid station?',
    },
    {
      'icon': Icons.accessible,
      'label': 'Wheelchair route',
      'query':
          'Show me wheelchair accessible routes to concessions from my section',
    },
    {
      'icon': Icons.volume_mute,
      'label': 'Quiet zone',
      'query': 'Find a sensory friendly quiet zone near me',
    },
    {
      'icon': Icons.directions,
      'label': 'Exit navigation',
      'query': 'What is the fastest exit route to avoid the post-match crowd?',
    },
    {
      'icon': Icons.translate,
      'label': '¿Hablas español?',
      'query':
          '¿Puedes ayudarme en español? ¿Dónde está la puerta de salida más cercana?',
    },
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
    final aiRepo = ref.watch(aiRepositoryProvider);

    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width >= 900;

    // Trigger scrolling when messages change
    _scrollToBottom();

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'StadiumGenie AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getOnSurface(isDark),
                    height: 1.1,
                  ),
                ),
                Text(
                  'FIFA 2026 Smart Assistant',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getOnSurfaceVariant(isDark),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.getSurface(isDark),
        elevation: 0,
        actions: [
          // Clear conversation button
          IconButton(
            icon: Icon(
              Icons.delete_sweep_outlined,
              color: AppColors.getOnSurfaceVariant(isDark),
            ),
            tooltip: 'Reset conversation',
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
                  // Location and Accessibility Context indicator bar
                  _buildContextIndicatorBar(settings, isDark),
                  if (!aiRepo.hasConfiguredApiKey && !_hideApiKeyBanner)
                    _buildSetupBanner(isDark),

                  // Error message banner
                  if (chatState.error != null)
                    _buildErrorBanner(chatState.error!, isDark),

                  // Message list view
                  Expanded(
                    child: chatState.messages.isEmpty
                        ? _buildWelcomeState(isDark)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: chatState.messages.length,
                            itemBuilder: (context, index) {
                              final msg = chatState.messages[index];
                              return ChatBubble(
                                message: msg,
                                isDark: isDark,
                                onSuggestionTap: (suggestion) =>
                                    _handleSend(suggestion),
                              );
                            },
                          ),
                  ),

                  // Suggested prompts quick access chips
                  if (chatState.messages.length <= 1)
                    _buildSuggestedChips(isDark),

                  // Message input panel
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

  Widget _buildWelcomeState(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Hero welcome icon
          Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  size: 48,
                  color: AppColors.primaryContainer,
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.05, 1.05),
                duration: 2000.ms,
              ),

          const SizedBox(height: 20),

          Text(
            'How can I help you today?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.getOnSurface(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about the stadium — navigation, queues, accessibility, or just chat in your language!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getOnSurfaceVariant(isDark),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          // Feature highlights
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureChip(Icons.location_on, 'Context-aware', isDark),
              _buildFeatureChip(Icons.translate, 'Multilingual', isDark),
              _buildFeatureChip(Icons.accessible, 'Accessible', isDark),
              _buildFeatureChip(Icons.bolt, 'Real-time data', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceContainer(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.getOutlineVariant(isDark).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryContainer),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.getOnSurface(isDark),
            ),
          ),
        ],
      ),
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
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildContextBadge(
            icon: Icons.location_on,
            label: 'Zone: ${settings.currentZone}',
            isDark: isDark,
          ),
          if (settings.wheelchairMode)
            _buildContextBadge(
              icon: Icons.accessible,
              label: 'Wheelchair mode',
              color: AppColors.primaryContainer,
              isDark: isDark,
            ),
          if (settings.sensoryFriendlyMode)
            _buildContextBadge(
              icon: Icons.volume_mute,
              label: 'Sensory friendly',
              color: AppColors.secondary,
              isDark: isDark,
            ),
          _buildContextBadge(
            icon: Icons.translate,
            label: 'Auto-translate',
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
        border: Border.all(color: activeColor.withValues(alpha: 0.2)),
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
              fontWeight: FontWeight.w600,
              color: activeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedChips(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'Quick questions',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.getOnSurfaceVariant(isDark),
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestedPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _suggestedPrompts[index];
                return AccessibilityWrapper(
                  label: 'Suggested: ${prompt["label"]}',
                  isButton: true,
                  child: InkWell(
                    onTap: () => _handleSend(prompt['query'] as String),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.getSurfaceContainer(isDark),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.getOutlineVariant(
                            isDark,
                          ).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            prompt['icon'] as IconData,
                            size: 14,
                            color: AppColors.primaryContainer,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            prompt['label'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.getOnSurface(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        border: Border(
          top: BorderSide(
            color: AppColors.getOutline(isDark).withValues(alpha: 0.12),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Chat text input
          Expanded(
            child: AccessibilityWrapper(
              label: 'Message input field',
              hint: 'Type your stadium question in any language',
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.getSurfaceContainerHigh(isDark),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.getOutlineVariant(
                      isDark,
                    ).withValues(alpha: 0.5),
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _handleSend,
                  maxLength: 500,
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) {
                        final remaining = 500 - currentLength;
                        final color = remaining < 40
                            ? AppColors.tertiary
                            : AppColors.getOnSurfaceVariant(isDark);
                        return Text(
                          '$remaining chars left',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        );
                      },
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Ask me anything in any language...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.getOnSurfaceVariant(
                        isDark,
                      ).withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  style: TextStyle(
                    color: AppColors.getOnSurface(isDark),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Send button
          AccessibilityWrapper(
            label: 'Send message',
            hint: 'Tap to ask the AI assistant',
            isButton: true,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isLoading
                    ? AppColors.primaryContainer.withValues(alpha: 0.5)
                    : AppColors.primaryContainer,
                shape: BoxShape.circle,
                boxShadow: isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(13.0),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _handleSend(_messageController.text),
                      padding: EdgeInsets.zero,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupBanner(bool isDark) {
    return Dismissible(
      key: const ValueKey('ai-setup-banner'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        setState(() => _hideApiKeyBanner = true);
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline,
              size: 18,
              color: AppColors.primaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Add AI_API_KEY in .env to enable Gemini responses. The app keeps working with simulated stadium guidance until then.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.getOnSurface(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
