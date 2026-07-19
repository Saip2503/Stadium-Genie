import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stadium_data_model.dart';
import '../providers/chat_provider.dart';
import '../theme/app_colors.dart';

/// A card highlighting eco-friendly transport options and CO2 savings metrics.
class SustainabilityCard extends ConsumerWidget {
  final StadiumData? data;
  final bool isDark;

  const SustainabilityCard({
    super.key,
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (data == null) return const SizedBox.shrink();

    int availableSpots = 0;
    int totalSpots = 0;
    for (final lot in data!.parkingLots.values) {
      availableSpots += lot.available;
      totalSpots += lot.total;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B3B2B) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2E7D32).withValues(alpha: 0.5)
              : const Color(0xFFC8E6C9),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco,
              color: Color(0xFF2E7D32),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '🌱 SUSTAINABILITY ACTION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Parking: $availableSpots/$totalSpots left',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose NJ Transit rail instead of driving to save ~2.4kg of CO₂ emissions. Total transit offset: ${((totalSpots - availableSpots) * 2.4).toStringAsFixed(1)} kg CO₂ saved!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getOnSurface(isDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              ref.read(chatProvider.notifier).sendMessage(
                'How can I take the NJ Transit train, and what are the carbon savings?',
              );
              Navigator.pushNamed(context, '/chat');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Eco route',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
