import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import 'accessibility_wrapper.dart';

/// Renders a persistent desktop side navigation bar matching the Stitch project spec
class SideNavBar extends StatelessWidget {
  final String activeRoute;
  final bool isDark;
  final Function(String) onNavigate;

  const SideNavBar({
    super.key,
    required this.activeRoute,
    required this.isDark,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      width: 288, // w-72 matching Stitch tokens
      padding: const EdgeInsets.all(16), // p-gutter
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        border: Border(
          right: BorderSide(
            color: AppColors.getOutline(isDark).withValues(alpha: 0.15),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Branding Header
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 8.0,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.stadium,
                      color: AppColors.primaryContainer,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "StadiumGenie",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryContainer,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),

          // User info profile card
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16.0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceContainer(isDark),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  backgroundColor: AppColors.primaryContainer.withValues(
                    alpha: 0.2,
                  ),
                  child: user?.photoURL == null
                      ? Icon(Icons.person, color: AppColors.primaryContainer)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? "Welcome, Fan",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getOnSurface(isDark),
                        ),
                      ),
                      Text(
                        user?.email ?? "Section 204, Row K",
                        overflow: TextOverflow.ellipsis,
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

          const Divider(),
          const SizedBox(height: 12),

          // Navigation list
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(route: '/', label: 'Home', icon: Icons.home),
                _buildNavItem(
                  route: '/chat',
                  label: 'AI Concierge',
                  icon: Icons.bolt,
                ),
                _buildNavItem(
                  route: '/settings',
                  label: 'Accessibility',
                  icon: Icons.accessibility_new,
                ),
              ],
            ),
          ),

          // Ask StadiumGenie gradient button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF9C27B0)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => onNavigate('/chat'),
                icon: const Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  "Ask StadiumGenie",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bottom World Cup tag
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                "FIFA WORLD CUP 2026",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.getOnSurfaceVariant(
                    isDark,
                  ).withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String route,
    required String label,
    required IconData icon,
  }) {
    final isActive = activeRoute == route;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: AccessibilityWrapper(
        label: "Navigate to $label",
        isButton: true,
        isSelected: isActive,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onNavigate(route),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isActive
                        ? Colors.white
                        : AppColors.getOnSurfaceVariant(isDark),
                    size: 22,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? Colors.white
                          : AppColors.getOnSurface(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
