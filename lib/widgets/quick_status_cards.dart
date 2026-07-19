import 'package:flutter/material.dart';
import '../models/stadium_data_model.dart';
import '../theme/app_colors.dart';
import 'accessibility_wrapper.dart';

/// A row of summary cards showing the fastest food, merch, and gate options.
class QuickStatusCards extends StatelessWidget {
  final StadiumData? data;
  final bool isDark;

  const QuickStatusCards({
    super.key,
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (data == null || data!.zones.isEmpty || data!.gates.isEmpty) {
      return const SizedBox.shrink();
    }

    final bestFood = data!.zonesByFoodQueue.first;
    final bestMerch = data!.zonesByMerchQueue.first;
    final bestGate = data!.gatesByQueue.first;

    final items = [
      (
        icon: Icons.fastfood_rounded,
        title: 'Fastest Food',
        value: '${bestFood.key} Zone',
        detail: '${bestFood.value.foodQueueMins} min wait',
        color: AppColors.secondary,
        bg: AppColors.secondaryContainer,
      ),
      (
        icon: Icons.storefront_rounded,
        title: 'Best Merch',
        value: '${bestMerch.key} Zone',
        detail: '${bestMerch.value.merchQueueMins} min wait',
        color: AppColors.primaryContainer,
        bg: AppColors.primaryContainer,
      ),
      (
        icon: Icons.door_front_door_rounded,
        title: 'Fastest Gate',
        value: bestGate.key,
        detail: '${bestGate.value.queueMins} min wait',
        color: AppColors.tertiaryContainer,
        bg: AppColors.tertiaryContainer,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.asMap().entries.map((entry) {
            final item = entry.value;
            return AccessibilityWrapper(
                  label: '${item.title}: ${item.value}, ${item.detail}',
                  child: SizedBox(
                    width: isNarrow
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 24) / 3,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(isDark),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.getOutlineVariant(
                            isDark,
                          ).withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: item.bg.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(item.icon, color: item.color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: AppColors.getOnSurfaceVariant(
                                      isDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.getOnSurface(isDark),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.bg.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.detail,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: item.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
          }).toList(),
        );
      },
    );
  }
}
