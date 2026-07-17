import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/stadium_data_model.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/side_nav_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/stadium_map.dart';
import '../widgets/zone_card.dart';
import '../widgets/gate_row_item.dart';
import '../widgets/accessibility_wrapper.dart';

/// Main Dashboard showing Map, Queue Times, Gate statuses and Live IoT alerts.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = settings.isDarkMode;
    final data = chatState.stadiumData;

    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      body: Row(
        children: [
          // Sidebar Nav for Desktop viewports
          if (isDesktop)
            SideNavBar(
              activeRoute: '/',
              isDark: isDark,
              onNavigate: (route) =>
                  Navigator.pushReplacementNamed(context, route),
            ),

          // Main screen contents area
          Expanded(
            child: chatState.isLoading && data == null
                ? const Center(child: CircularProgressIndicator())
                : SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live IoT Alert banner if any warning alert exists
                        if (data != null && data.alerts.isNotEmpty)
                          _buildAlertBanner(data.alerts, isDark),

                        // Dashboard Scrollable Body
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top header details (Wrapped in Row with Expanded to prevent text overflows)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            child: Image.asset(
                                              'assets/images/stadium.png',
                                              height: 150,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Container(
                                                    height: 150,
                                                    color: AppColors
                                                        .surfaceContainer,
                                                    alignment: Alignment.center,
                                                    child: Icon(
                                                      Icons.stadium,
                                                      color: AppColors
                                                          .primaryContainer,
                                                      size: 44,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          AccessibilityWrapper(
                                            label: "Welcome message header",
                                            header: true,
                                            child: Text(
                                              "FIFA 2026 World Cup",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.5,
                                                color:
                                                    AppColors.primaryContainer,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            data?.stadiumName ??
                                                "MetLife Stadium Operations",
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.getOnSurface(
                                                isDark,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Refresh status pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.getSurfaceContainer(
                                          isDark,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.sync,
                                            size: 14,
                                            color: AppColors.secondary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "LIVE mock feed",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  AppColors.getOnSurfaceVariant(
                                                    isDark,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _buildQuickStatusCards(data, isDark),
                                const SizedBox(height: 24),

                                // Layout adapts: Map + stats grid side-by-side on wide screens, stacked on small screens
                                if (mediaQuery.size.width >= 1100)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: _buildMapSection(data, isDark),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        flex: 5,
                                        child: _buildZonesGrid(
                                          data,
                                          settings.currentZone,
                                          isDark,
                                          ref,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildMapSection(data, isDark),
                                      const SizedBox(height: 24),
                                      _buildZonesGrid(
                                        data,
                                        settings.currentZone,
                                        isDark,
                                        ref,
                                      ),
                                    ],
                                  ),

                                const SizedBox(height: 32),
                                _buildGatesSection(data, isDark),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),

      // Floating AI concierge action triggers chat modal
      floatingActionButton:
          FloatingActionButton.extended(
                onPressed: () => Navigator.pushNamed(context, '/chat'),
                backgroundColor: AppColors.primaryContainer,
                icon: const Icon(Icons.bolt, color: Colors.white),
                label: const Text(
                  "Ask StadiumGenie",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.03, 1.03),
                duration: 1500.ms,
                curve: Curves.easeInOut,
              ),

      // Mobile Navigation for phone sizes
      bottomNavigationBar: !isDesktop
          ? BottomNavBar(
              activeRoute: '/',
              isDark: isDark,
              onNavigate: (route) =>
                  Navigator.pushReplacementNamed(context, route),
            )
          : null,
    );
  }

  Widget _buildAlertBanner(List<StadiumAlert> alerts, bool isDark) {
    final alert = alerts.firstWhere(
      (a) => a.severity == 'warning',
      orElse: () => alerts.first,
    );

    return Container(
      width: double.infinity,
      color: AppColors.tertiaryContainer.withValues(alpha: 0.9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert.message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 16),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(StadiumData? data, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceContainer(isDark),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Interactive Arena Map",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getOnSurface(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap sector to simulate your physical location.",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getOnSurfaceVariant(isDark),
            ),
          ),
          const SizedBox(height: 20),
          StadiumMap(stadiumData: data, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildZonesGrid(
    StadiumData? data,
    String currentZone,
    bool isDark,
    WidgetRef ref,
  ) {
    if (data == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Zone Concession wait times",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.getOnSurface(isDark),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.05,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: data.zones.entries.map((e) {
            return ZoneCard(
              zone: e.value,
              isSelected: currentZone == e.key,
              isDark: isDark,
              onTap: () {
                ref.read(settingsProvider.notifier).setCurrentZone(e.key);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickStatusCards(StadiumData? data, bool isDark) {
    if (data == null) return const SizedBox.shrink();

    final bestFood = data.zonesByFoodQueue.first;
    final bestMerch = data.zonesByMerchQueue.first;
    final bestGate = data.gatesByQueue.first;

    final items = [
      (
        icon: Icons.fastfood,
        title: 'Fastest food',
        value: '${bestFood.key} Zone',
        detail: '${bestFood.value.foodQueueMins} min wait',
        color: AppColors.secondary,
      ),
      (
        icon: Icons.storefront,
        title: 'Best merch',
        value: '${bestMerch.key} Zone',
        detail: '${bestMerch.value.merchQueueMins} min wait',
        color: AppColors.primaryContainer,
      ),
      (
        icon: Icons.door_front_door,
        title: 'Fastest gate',
        value: bestGate.key,
        detail: '${bestGate.value.queueMins} min wait',
        color: AppColors.tertiaryContainer,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.getOutline(
                        isDark,
                      ).withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: item.color.withValues(alpha: 0.12),
                        child: Icon(item.icon, color: item.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.getOnSurfaceVariant(isDark),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.value,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.getOnSurface(isDark),
                              ),
                            ),
                            Text(
                              item.detail,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.getOnSurfaceVariant(isDark),
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

  Widget _buildGatesSection(StadiumData? data, bool isDark) {
    if (data == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Access Gates Status",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.getOnSurface(isDark),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: data.gates.values.map((gate) {
              return GateRowItem(gate: gate, isDark: isDark);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
