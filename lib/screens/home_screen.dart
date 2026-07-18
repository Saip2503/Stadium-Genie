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
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
                                _buildHeroSection(data, isDark, isDesktop),
                                const SizedBox(height: 24),

                                // Quick AI Suggestions Strip
                                _buildAIQuickActions(isDark),
                                const SizedBox(height: 24),

                                // Quick Status Summary Cards
                                _buildQuickStatusCards(data, isDark),
                                const SizedBox(height: 24),

                                // Adaptive layout: Map + zones grid
                                if (mediaQuery.size.width >= 1100)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child:
                                            _buildMapSection(data, isDark),
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
                                _buildConcoursePreview(isDark),
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
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.03, 1.03),
            duration: 1500.ms,
            curve: Curves.easeInOut,
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
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryContainer),
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

  /// Hero image with gradient overlay and stadium info
  Widget _buildHeroSection(StadiumData? data, bool isDark, bool isDesktop) {
    return Container(
      width: double.infinity,
      height: isDesktop ? 240 : 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Real stadium photo
            Image.asset(
              'assets/images/stadium.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // Gradient overlay for text legibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),

            // Hero content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Live Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) => Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: _pulseController.value,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'LIVE DATA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'FIFA WORLD CUP 2026',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data?.stadiumName ?? 'MetLife Stadium',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Attendance badge
                  if (data != null)
                    Row(
                      children: [
                        _buildHeroBadge(
                          Icons.people,
                          '${_formatNum(data.capacity)} cap',
                        ),
                        const SizedBox(width: 8),
                        _buildHeroBadge(
                          Icons.emoji_events,
                          'Group Stage · Match Day',
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: 0.04, duration: 500.ms);
  }

  Widget _buildHeroBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return n.toString();
  }

  /// Quick AI prompts row — contextual shortcuts
  Widget _buildAIQuickActions(bool isDark) {
    final actions = [
      (icon: Icons.wc, label: 'Nearest restroom', query: 'Find the nearest restroom with shortest queue from my zone'),
      (icon: Icons.fastfood, label: 'Fastest food', query: 'Which food stand has the shortest wait near me?'),
      (icon: Icons.accessible, label: 'Accessible route', query: 'Show me wheelchair accessible routes to concessions'),
      (icon: Icons.translate, label: 'Help me in Spanish', query: '¿Dónde está la salida más cercana?'),
      (icon: Icons.directions, label: 'My seat direction', query: 'How do I get to my seat from the main entrance?'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt, size: 16, color: AppColors.primaryContainer),
            const SizedBox(width: 6),
            Text(
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
                icon: action.icon,
                label: action.label,
                onTap: () {
                  ref
                      .read(chatProvider.notifier)
                      .sendMessage(action.query);
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
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
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

  Widget _buildQuickStatusCards(StadiumData? data, bool isDark) {
    if (data == null) return const SizedBox.shrink();

    final bestFood = data.zonesByFoodQueue.first;
    final bestMerch = data.zonesByMerchQueue.first;
    final bestGate = data.gatesByQueue.first;

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
                      color: AppColors.getOutlineVariant(isDark)
                          .withValues(alpha: 0.5),
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
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: AppColors.getOnSurfaceVariant(isDark),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.value,
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
            )
                .animate()
                .fade(delay: (entry.key * 80).ms, duration: 400.ms)
                .slideY(begin: 0.1, duration: 400.ms);
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

  /// Stadium concourse preview section
  Widget _buildConcoursePreview(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Concourse image
            Image.asset(
              'assets/images/stadium_concourse.png',
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.surfaceContainer,
                      AppColors.surfaceContainerHigh,
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.stadium,
                    size: 64,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ),
            ),

            // Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      AppColors.primaryContainer.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Call-to-action content
            Positioned(
              right: 24,
              top: 0,
              bottom: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Navigate the\nConcourse',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryContainer,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.bolt, size: 16),
                      label: const Text(
                        'Ask AI Guide',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
