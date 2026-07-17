import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stadium_data_model.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import 'accessibility_wrapper.dart';

/// A premium interactive visual representation of the stadium zones.
/// Allows user to select their location by clicking corresponding parts.
/// Color-coded based on mock IoT real-time crowd congestion data.
class StadiumMap extends ConsumerWidget {
  final StadiumData? stadiumData;
  final bool isDark;

  const StadiumMap({
    super.key,
    required this.stadiumData,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final activeZone = settings.currentZone;

    return AccessibilityWrapper(
      label:
          "Interactive Stadium Map. Current active zone selected is $activeZone.",
      hint:
          "Tap on any zone (North, South, East, West) to set your location context.",
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth
              : constraints.maxHeight;

          // Limit size to fit nicely
          final mapSize = size > 400.0 ? 400.0 : size;

          return Center(
            child: SizedBox(
              width: mapSize,
              height: mapSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Stadium outer layout outline ring
                  Container(
                    width: mapSize * 0.95,
                    height: mapSize * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.all(
                        Radius.elliptical(mapSize * 0.47, mapSize * 0.4),
                      ),
                      border: Border.all(
                        color: AppColors.getOutline(
                          isDark,
                        ).withValues(alpha: 0.3),
                        width: 4,
                      ),
                    ),
                  ),

                  // Middle field arena circle
                  Container(
                    width: mapSize * 0.45,
                    height: mapSize * 0.3,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withValues(
                        alpha: 0.2,
                      ),
                      borderRadius: BorderRadius.all(
                        Radius.elliptical(mapSize * 0.22, mapSize * 0.15),
                      ),
                      border: Border.all(color: AppColors.secondary, width: 2),
                    ),
                    child: const Center(
                      child: Text(
                        "FIFA Arena",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ),

                  // North Zone Button
                  Positioned(
                    top: 10,
                    child: _buildZoneSector(
                      ref: ref,
                      zoneId: 'North',
                      activeZone: activeZone,
                      width: mapSize * 0.5,
                      height: mapSize * 0.18,
                      label: "NORTH",
                      icon: Icons.keyboard_arrow_up,
                    ),
                  ),

                  // South Zone Button
                  Positioned(
                    bottom: 10,
                    child: _buildZoneSector(
                      ref: ref,
                      zoneId: 'South',
                      activeZone: activeZone,
                      width: mapSize * 0.5,
                      height: mapSize * 0.18,
                      label: "SOUTH",
                      icon: Icons.keyboard_arrow_down,
                    ),
                  ),

                  // West Zone Button
                  Positioned(
                    left: 10,
                    child: _buildZoneSector(
                      ref: ref,
                      zoneId: 'West',
                      activeZone: activeZone,
                      width: mapSize * 0.18,
                      height: mapSize * 0.5,
                      label: "WEST",
                      icon: Icons.keyboard_arrow_left,
                      isVertical: true,
                    ),
                  ),

                  // East Zone Button
                  Positioned(
                    right: 10,
                    child: _buildZoneSector(
                      ref: ref,
                      zoneId: 'East',
                      activeZone: activeZone,
                      width: mapSize * 0.18,
                      height: mapSize * 0.5,
                      label: "EAST",
                      icon: Icons.keyboard_arrow_right,
                      isVertical: true,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildZoneSector({
    required WidgetRef ref,
    required String zoneId,
    required String activeZone,
    required double width,
    required double height,
    required String label,
    required IconData icon,
    bool isVertical = false,
  }) {
    final isActive = activeZone == zoneId;
    final zoneData = stadiumData?.zones[zoneId];

    // Determine congestion status color scheme
    Color statusColor;
    if (zoneData == null) {
      statusColor = AppColors.outlineVariant;
    } else {
      statusColor = switch (zoneData.crowdLevel) {
        CrowdLevel.low => AppColors.secondaryContainer,
        CrowdLevel.medium => AppColors.outlineVariant,
        CrowdLevel.high => AppColors.tertiaryContainer,
      };
    }

    return InkWell(
      onTap: () {
        ref.read(settingsProvider.notifier).setCurrentZone(zoneId);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryContainer.withValues(
                  alpha: isDark ? 0.35 : 0.15,
                )
              : AppColors.getSurfaceContainer(isDark).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppColors.primaryContainer
                : AppColors.getOutline(isDark).withValues(alpha: 0.2),
            width: isActive ? 2.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Flex(
            direction: isVertical ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive
                    ? AppColors.primaryContainer
                    : AppColors.getOnSurface(isDark),
                size: 20,
              ),
              const SizedBox(width: 4, height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isActive
                      ? AppColors.primaryContainer
                      : AppColors.getOnSurface(isDark),
                ),
              ),
              const SizedBox(width: 4, height: 4),
              // Little status dot for congestion
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: zoneData?.crowdLevel == CrowdLevel.high
                      ? [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.8),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
