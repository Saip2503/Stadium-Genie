import 'package:flutter/material.dart';
import '../models/stadium_data_model.dart';
import '../theme/app_colors.dart';
import 'accessibility_wrapper.dart';

/// Stat card display for individual stadium zones.
/// Displays queue times for restrooms & concessions, accessibility indicators,
/// and crowd level using color-coded badge.
class ZoneCard extends StatelessWidget {
  final ZoneData zone;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const ZoneCard({
    super.key,
    required this.zone,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Colors depending on crowd level
    final badgeColor = switch (zone.crowdLevel) {
      CrowdLevel.low => AppColors.secondaryContainer,
      CrowdLevel.medium => AppColors.outlineVariant,
      CrowdLevel.high => AppColors.tertiaryContainer,
    };

    final onBadgeColor = switch (zone.crowdLevel) {
      CrowdLevel.low => AppColors.onSecondaryContainer,
      CrowdLevel.medium => AppColors.onSurface,
      CrowdLevel.high => Colors.white,
    };

    return AccessibilityWrapper(
      label:
          "${zone.displayName} status: Concession queue ${zone.foodQueueMins} minutes. Restroom queue ${zone.restroomQueueMins} minutes. Merchandise queue ${zone.merchQueueMins} minutes. Crowd level is ${zone.crowdLevelLabel}. ${isSelected ? 'Current active location.' : 'Double tap to select location.'}",
      isButton: true,
      child: Card(
        color: isSelected
            ? AppColors.primaryContainer.withValues(alpha: isDark ? 0.25 : 0.08)
            : AppColors.getSurface(isDark),
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected
                ? AppColors.primaryContainer
                : AppColors.getOutline(isDark).withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header (Zone name + Crowd level indicator badge)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      zone.displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getOnSurface(isDark),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        zone.crowdLevelLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: onBadgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Concessions metric
                Row(
                  children: [
                    Icon(
                      Icons.fastfood,
                      size: 18,
                      color: AppColors.getOnSurfaceVariant(isDark),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Concessions: ",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getOnSurfaceVariant(isDark),
                      ),
                    ),
                    Text(
                      "${zone.foodQueueMins} mins",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getOnSurface(isDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Restroom metric
                Row(
                  children: [
                    Icon(
                      Icons.wc,
                      size: 18,
                      color: AppColors.getOnSurfaceVariant(isDark),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Restroom: ",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getOnSurfaceVariant(isDark),
                      ),
                    ),
                    Text(
                      "${zone.restroomQueueMins} mins",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getOnSurface(isDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Merchandise metric
                Row(
                  children: [
                    Icon(
                      Icons.storefront,
                      size: 18,
                      color: AppColors.getOnSurfaceVariant(isDark),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Merch: ",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getOnSurfaceVariant(isDark),
                      ),
                    ),
                    Text(
                      "${zone.merchQueueMins} mins",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getOnSurface(isDark),
                      ),
                    ),
                  ],
                ),

                const Spacer(),
                const Divider(),

                // Accessibility features icon indicators footer
                Row(
                  children: [
                    if (zone.isWheelchairAccessible)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(
                          Icons.accessible,
                          size: 16,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    if (zone.hasElevator)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(
                          Icons.elevator,
                          size: 16,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    if (zone.isSensoryFriendly)
                      Icon(
                        Icons.volume_mute,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                    const Spacer(),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: AppColors.primaryContainer,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
