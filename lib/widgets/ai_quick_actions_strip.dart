import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../theme/app_colors.dart';

/// A horizontal strip of quick action chips that send predefined
/// contextual queries to the StadiumGenie AI assistant.
class AIQuickActionsStrip extends ConsumerWidget {
  final bool isDark;

  const AIQuickActionsStrip({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      (
        icon: Icons.wc,
        label: 'Nearest restroom',
        query: 'Find the nearest restroom with shortest queue from my zone',
      ),
      (
        icon: Icons.fastfood,
        label: 'Fastest food',
        query: 'Which food stand has the shortest wait near me?',
      ),
      (
        icon: Icons.accessible,
        label: 'Accessible route',
        query: 'Show me wheelchair accessible routes to concessions',
      ),
      (
        icon: Icons.translate,
        label: 'Help me in Spanish',
        query: '¿Dónde está la salida más cercana?',
      ),
      (
        icon: Icons.directions,
        label: 'My seat direction',
        query: 'How do I get to my seat from the main entrance?',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt, size: 16, color: AppColors.primaryContainer),
            const SizedBox(width: 6),
            const Text(
              'Quick AI Assist',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.primaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final action = actions[index];
              return _buildQuickChip(
                context: context,
                ref: ref,
                icon: action.icon,
                label: action.label,
                onTap: () {
                  ref.read(chatProvider.notifier).sendMessage(action.query);
                  Navigator.pushNamed(context, '/chat');
                },
                isDark: isDark,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChip({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceContainer(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.getOutlineVariant(isDark).withValues(alpha: 0.6),
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.getOnSurface(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
