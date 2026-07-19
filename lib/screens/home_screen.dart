import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../widgets/emergency_info_card.dart';
import '../widgets/home_hero_section.dart';
import '../widgets/ai_quick_actions_strip.dart';
import '../widgets/quick_status_cards.dart';
import '../widgets/sustainability_card.dart';
import '../widgets/concourse_preview_card.dart';

/// Main Dashboard showing Map, Queue Times, Gate statuses and Live IoT alerts.
/// Refactored for modularity and high-quality design-system compliance.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  @override
  Widget build(BuildContext context) {
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
                ? _buildLoadingState(isDark)
                : SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live IoT Alert banner
                        if (data != null && data.alerts.isNotEmpty)
                          _buildAlertBanner(data.alerts, isDark),

                        // Dashboard Scrollable Body
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Hero Stadium Image + header overlay
                                HomeHeroSection(data: data, isDark: isDark, isDesktop: isDesktop),
                                const SizedBox(height: 24),

                                // Quick AI Suggestions Strip
                                AIQuickActionsStrip(isDark: isDark),
                                const SizedBox(height: 24),

                                // Quick Status Summary Cards
                                QuickStatusCards(data: data, isDark: isDark),
                                const SizedBox(height: 24),

                                // Sustainability Card with CO2 metrics
                                SustainabilityCard(data: data, isDark: isDark),
                                const SizedBox(height: 24),

                                // Emergency & Services Card with pulse animation
                                EmergencyInfoCard(data: data, isDark: isDark),
                                const SizedBox(height: 24),

                                // Adaptive layout: Map + zones grid
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
                                const SizedBox(height: 32),
                                ConcoursePreviewCard(
                                  isDark: isDark,
                                  onAskAI: () => Navigator.pushNamed(context, '/chat'),
                                ),
                                const SizedBox(height: 80),
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

      // Floating AI concierge action button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/chat'),
        backgroundColor: AppColors.primaryContainer,
        elevation: 8,
        icon: const Icon(Icons.bolt, color: Colors.white),
        label: const Text(
          'Ask StadiumGenie',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),

      // Mobile Bottom Nav
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

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primaryContainer,
            ),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading Stadium Data...',
            style: TextStyle(
              color: AppColors.getOnSurfaceVariant(isDark),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner(List<StadiumAlert> alerts, bool isDark) {
    final alert = alerts.firstWhere(
      (a) => a.severity == 'warning',
      orElse: () => alerts.first,
    );

    return Container(
      width: double.infinity,
      color: AppColors.tertiaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert.message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            tooltip: "Dismiss Alert",
            icon: const Icon(Icons.close, color: Colors.white, size: 16),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
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
        border: Border.all(
          color: AppColors.getOutlineVariant(isDark).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: AppColors.primaryContainer,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interactive Arena Map',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getOnSurface(isDark),
                    ),
                  ),
                  Text(
                    'Tap zone to set your location',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getOnSurfaceVariant(isDark),
                    ),
                  ),
                ],
              ),
            ],
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Zone Wait Times',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.getOnSurface(isDark),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Mock IoT Feed',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
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

  Widget _buildGatesSection(StadiumData? data, bool isDark) {
    if (data == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.meeting_room_outlined,
              size: 16,
              color: AppColors.primaryContainer,
            ),
            const SizedBox(width: 8),
            Text(
              'Access Gates Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.getOnSurface(isDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
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
