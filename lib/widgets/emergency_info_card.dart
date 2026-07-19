import 'package:flutter/material.dart';
import '../models/stadium_data_model.dart';
import 'accessibility_wrapper.dart';

/// A card widget highlighting emergency services (first aid locations)
/// and guest services for fans and staff, styled to meet accessibility design needs.
/// Animates with a pulsing red border when critical alerts are active.
class EmergencyInfoCard extends StatefulWidget {
  final StadiumData? data;
  final bool isDark;

  const EmergencyInfoCard({
    super.key,
    required this.data,
    required this.isDark,
  });

  @override
  State<EmergencyInfoCard> createState() => _EmergencyInfoCardState();
}

class _EmergencyInfoCardState extends State<EmergencyInfoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _updateAnimation();
  }

  @override
  void didUpdateWidget(EmergencyInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimation();
  }

  void _updateAnimation() {
    final hasCriticalAlert = widget.data?.alerts.any((a) => a.severity == 'warning') ?? false;
    if (hasCriticalAlert) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    if (data == null) return const SizedBox.shrink();

    final firstAid = data.firstAidLocations;
    final guestServices = data.guestServicesLocation;

    if (firstAid.isEmpty && guestServices == null) {
      return const SizedBox.shrink();
    }

    final isDark = widget.isDark;
    final redAccent = isDark ? Colors.redAccent.shade200 : Colors.red.shade700;
    final cardBg = isDark ? const Color(0xFF2C1A1A) : const Color(0xFFFFF2F2);
    final textTheme = Theme.of(context).textTheme;

    return AccessibilityWrapper(
      label: "Emergency and Guest Services Information",
      hint: "Read-only summary of medical aid and customer service desks in the stadium.",
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: redAccent.withValues(alpha: widget.data?.alerts.any((a) => a.severity == 'warning') ?? false 
                  ? _animation.value 
                  : 0.5), 
                width: 1.5,
              ),
              boxShadow: widget.data?.alerts.any((a) => a.severity == 'warning') ?? false
                  ? [
                      BoxShadow(
                        color: redAccent.withValues(alpha: 0.2 * _animation.value),
                        blurRadius: 10 * _animation.value,
                        spreadRadius: 2 * _animation.value,
                      )
                    ]
                  : null,
            ),
            child: child,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: redAccent, size: 24),
                const SizedBox(width: 8),
                Text(
                  "Emergency & Services",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (firstAid.isNotEmpty) ...[
              Text(
                "First Aid Locations:",
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                firstAid.join(" • "),
                style: textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
            ],
            if (firstAid.isNotEmpty && guestServices != null)
              const SizedBox(height: 12),
            if (guestServices != null) ...[
              Text(
                "Guest Services Hub:",
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                guestServices,
                style: textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
