import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/stadium_data_model.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import 'accessibility_wrapper.dart';

/// A premium interactive visual representation of the stadium zones.
/// Uses the real stadium map image as background.
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
          'Interactive Stadium Map. Current active zone selected is $activeZone.',
      hint:
          'Tap on any zone (North, South, East, West) to set your location context.',
      child: Column(
        children: [
          // Map image with overlay zone buttons
          LayoutBuilder(
            builder: (context, constraints) {
              final mapWidth = constraints.maxWidth;
              final mapHeight = mapWidth * 0.62; // stadium-ish aspect ratio

              return SizedBox(
                width: mapWidth,
                height: mapHeight,
                child: Stack(
                  children: [
                    // Real stadium map image as background
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/stadium_map.png',
                        width: mapWidth,
                        height: mapHeight,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackMap(mapWidth, mapHeight, isDark),
                      ),
                    ),

                    // Semi-transparent overlay to enhance readability
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: mapWidth,
                        height: mapHeight,
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.35)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),

                    // Zone tap-overlay buttons positioned on top
                    // North Zone — top center
                    Positioned(
                      top: 4,
                      left: mapWidth * 0.3,
                      width: mapWidth * 0.4,
                      height: mapHeight * 0.22,
                      child: _buildZoneButton(
                        ref: ref,
                        zoneId: 'North',
                        activeZone: activeZone,
                        label: 'NORTH',
                        icon: Icons.keyboard_arrow_up,
                      ),
                    ),

                    // South Zone — bottom center
                    Positioned(
                      bottom: 4,
                      left: mapWidth * 0.3,
                      width: mapWidth * 0.4,
                      height: mapHeight * 0.22,
                      child: _buildZoneButton(
                        ref: ref,
                        zoneId: 'South',
                        activeZone: activeZone,
                        label: 'SOUTH',
                        icon: Icons.keyboard_arrow_down,
                      ),
                    ),

                    // West Zone — left
                    Positioned(
                      top: mapHeight * 0.25,
                      left: 4,
                      width: mapWidth * 0.18,
                      height: mapHeight * 0.5,
                      child: _buildZoneButton(
                        ref: ref,
                        zoneId: 'West',
                        activeZone: activeZone,
                        label: 'W',
                        icon: Icons.keyboard_arrow_left,
                        isVertical: true,
                      ),
                    ),

                    // East Zone — right
                    Positioned(
                      top: mapHeight * 0.25,
                      right: 4,
                      width: mapWidth * 0.18,
                      height: mapHeight * 0.5,
                      child: _buildZoneButton(
                        ref: ref,
                        zoneId: 'East',
                        activeZone: activeZone,
                        label: 'E',
                        icon: Icons.keyboard_arrow_right,
                        isVertical: true,
                      ),
                    ),

                    // Center field label
                    Positioned(
                      top: mapHeight * 0.38,
                      left: mapWidth * 0.3,
                      width: mapWidth * 0.4,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            '⚽ FIFA ARENA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Zone status legend
          _buildZoneLegend(activeZone),
        ],
      ),
    );
  }

  Widget _buildZoneButton({
    required WidgetRef ref,
    required String zoneId,
    required String activeZone,
    required String label,
    required IconData icon,
    bool isVertical = false,
  }) {
    final isActive = activeZone == zoneId;
    final zoneData = stadiumData?.zones[zoneId];

    Color statusColor;
    if (zoneData == null) {
      statusColor = AppColors.outlineVariant;
    } else {
      statusColor = switch (zoneData.crowdLevel) {
        CrowdLevel.low => AppColors.secondaryContainer,
        CrowdLevel.medium => const Color(0xFFFFD04D),
        CrowdLevel.high => AppColors.tertiaryContainer,
      };
    }

    return InkWell(
      onTap: () => ref.read(settingsProvider.notifier).setCurrentZone(zoneId),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryContainer.withValues(alpha: 0.8)
              : Colors.black.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.4),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Flex(
            direction: isVertical ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: isVertical ? 14 : 16,
              ),
              SizedBox(width: isVertical ? 0 : 3, height: isVertical ? 2 : 0),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: isVertical ? 0 : 4, height: isVertical ? 3 : 0),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: zoneData?.crowdLevel == CrowdLevel.high
                      ? [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.9),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(target: isActive ? 1 : 0)
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.05, 1.05),
          duration: 200.ms,
        );
  }

  /// Crowd level legend row
  Widget _buildZoneLegend(String activeZone) {
    final zones = stadiumData?.zones;
    if (zones == null) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: zones.entries.map((e) {
        final zone = e.value;
        final isActive = activeZone == e.key;

        final dotColor = switch (zone.crowdLevel) {
          CrowdLevel.low => AppColors.secondaryContainer,
          CrowdLevel.medium => const Color(0xFFFFD04D),
          CrowdLevel.high => AppColors.tertiaryContainer,
        };

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryContainer.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? AppColors.primaryContainer
                  : AppColors.outlineVariant.withValues(alpha: 0.5),
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${zone.displayName} — ${zone.crowdLevelLabel}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? AppColors.primaryContainer
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Fallback drawn map if image fails to load
  Widget _buildFallbackMap(double width, double height, bool isDark) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.getSurfaceContainer(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getOutline(isDark).withValues(alpha: 0.3),
        ),
      ),
      child: CustomPaint(
        painter: _StadiumOutlinePainter(isDark: isDark),
        child: const Center(
          child: Text(
            '⚽ FIFA Arena',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom fallback painter for stadium outline
class _StadiumOutlinePainter extends CustomPainter {
  final bool isDark;

  _StadiumOutlinePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.getOutline(isDark).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final outerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.88,
      height: size.height * 0.78,
    );

    canvas.drawOval(outerRect, paint);

    // Inner field
    final innerPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final innerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.45,
      height: size.height * 0.35,
    );

    canvas.drawOval(innerRect, innerPaint);

    final innerBorderPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawOval(innerRect, innerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
