import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'accessibility_wrapper.dart';

/// Renders a thumb-friendly bottom navigation bar for mobile/tablet screen sizes.
class BottomNavBar extends StatelessWidget {
  final String activeRoute;
  final bool isDark;
  final Function(String) onNavigate;

  const BottomNavBar({
    super.key,
    required this.activeRoute,
    required this.isDark,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: AppColors.getOutline(isDark).withValues(alpha: 0.15),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              '/',
              Icons.dashboard,
              'Home',
              'Home dashboard screen',
            ),
            _buildNavItem(
              '/chat',
              Icons.chat_bubble,
              'AI Assistant',
              'AI assistant screen',
            ),
            _buildNavItem(
              '/settings',
              Icons.settings,
              'Settings',
              'Settings and accessibility options',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String route, IconData icon, String label, String desc) {
    final isActive = activeRoute == route;
    final activeColor = AppColors.primaryContainer;
    final inactiveColor = AppColors.getOnSurfaceVariant(isDark);

    return AccessibilityWrapper(
      label: "$label tab button",
      hint: "Double tap to go to $desc",
      isButton: true,
      isSelected: isActive,
      child: InkWell(
        onTap: () => onNavigate(route),
        child: SizedBox(
          width: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
