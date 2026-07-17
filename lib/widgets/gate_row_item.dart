import 'package:flutter/material.dart';
import '../models/stadium_data_model.dart';
import '../theme/app_colors.dart';
import 'accessibility_wrapper.dart';

/// Renders a horizontal card representing the status of an entry gate.
class GateRowItem extends StatelessWidget {
  final GateData gate;
  final bool isDark;

  const GateRowItem({super.key, required this.gate, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final statusColor = gate.queueMins < 10
        ? AppColors.secondaryContainer
        : (gate.queueMins < 20
              ? AppColors.outlineVariant
              : AppColors.tertiaryContainer);

    final onStatusColor = gate.queueMins < 10
        ? AppColors.onSecondaryContainer
        : (gate.queueMins < 20 ? AppColors.onSurface : Colors.white);

    return AccessibilityWrapper(
      label:
          "${gate.name} entry status: Wait time is ${gate.queueMins} minutes. ${gate.isOpen ? 'Open.' : 'Closed.'} ${gate.isWheelchairAccessible ? 'Wheelchair accessible entrance.' : ''}",
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 180,
        decoration: BoxDecoration(
          color: AppColors.getSurfaceContainer(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.getOutline(isDark).withValues(alpha: 0.15),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  gate.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getOnSurface(isDark),
                  ),
                ),
                if (gate.isWheelchairAccessible)
                  Icon(
                    Icons.accessible,
                    size: 16,
                    color: AppColors.primaryContainer,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              gate.location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.getOnSurfaceVariant(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${gate.queueMins} min",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: onStatusColor,
                    ),
                  ),
                ),
                Text(
                  gate.isOpen ? "Open" : "Closed",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: gate.isOpen
                        ? AppColors.secondary
                        : AppColors.getOnSurfaceVariant(isDark),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
