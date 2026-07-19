import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/side_nav_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/accessibility_wrapper.dart';

/// Settings & Accessibility configuration dashboard screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDark = settings.isDarkMode;

    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.accessibility_new, color: AppColors.primaryContainer),
            const SizedBox(width: 8),
            Text(
              "Settings & Accessibility",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getOnSurface(isDark),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.getSurface(isDark),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.getOnSurface(isDark)),
        shape: Border(
          bottom: BorderSide(
            color: AppColors.getOutline(isDark).withValues(alpha: 0.15),
          ),
        ),
      ),
      body: Row(
        children: [
          // Sidebar Nav for Desktop viewports
          if (isDesktop)
            SideNavBar(
              activeRoute: '/settings',
              isDark: isDark,
              onNavigate: (route) =>
                  Navigator.pushReplacementNamed(context, route),
            ),

          // Main settings layout list
          Expanded(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  // Section: Profile details
                  ...[
                    _buildSectionHeader("Authenticated Profile", isDark),
                    _buildCard(
                      isDark: isDark,
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundImage:
                                  FirebaseAuth.instance.currentUser?.photoURL !=
                                      null
                                  ? NetworkImage(
                                      FirebaseAuth
                                          .instance
                                          .currentUser!
                                          .photoURL!,
                                    )
                                  : null,
                              backgroundColor: AppColors.primaryContainer
                                  .withValues(alpha: 0.2),
                              child:
                                  FirebaseAuth.instance.currentUser?.photoURL ==
                                      null
                                  ? const Icon(
                                      Icons.person,
                                      color: AppColors.primary,
                                    )
                                  : null,
                            ),
                            title: Text(
                              FirebaseAuth.instance.currentUser?.displayName ??
                                  "FIFA Fan",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              FirebaseAuth.instance.currentUser?.email ??
                                  "Not signed in",
                              style: TextStyle(
                                color: AppColors.getOnSurfaceVariant(isDark),
                                fontSize: 12,
                              ),
                            ),
                            trailing: TextButton.icon(
                              onPressed: () async {
                                await AuthService().signOut();
                                if (context.mounted) {
                                  Navigator.pushReplacementNamed(context, '/');
                                }
                              },
                              icon: const Icon(Icons.logout, size: 16),
                              label: const Text("Sign Out"),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Section: Location Simulation
                  _buildSectionHeader("Current Location Context", isDark),
                  _buildCard(
                    isDark: isDark,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.location_on,
                            color: AppColors.primaryContainer,
                          ),
                          title: const Text(
                            "Simulated Seating Zone",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            "Updates the context passed to the AI assistant",
                          ),
                          trailing: AccessibilityWrapper(
                            label:
                                "Select your zone location dropdown menu. Currently selected: ${settings.currentZone}",
                            isButton: true,
                            child: DropdownButton<String>(
                              value: settings.currentZone,
                              dropdownColor: AppColors.getSurface(isDark),
                              style: TextStyle(
                                color: AppColors.getOnSurface(isDark),
                                fontWeight: FontWeight.bold,
                              ),
                              underline: const SizedBox.shrink(),
                              onChanged: (String? value) {
                                if (value != null) {
                                  ref
                                      .read(settingsProvider.notifier)
                                      .setCurrentZone(value);
                                }
                              },
                              items: const [
                                DropdownMenuItem(
                                  value: 'North',
                                  child: Text("North Zone"),
                                ),
                                DropdownMenuItem(
                                  value: 'South',
                                  child: Text("South Zone"),
                                ),
                                DropdownMenuItem(
                                  value: 'East',
                                  child: Text("East Zone"),
                                ),
                                DropdownMenuItem(
                                  value: 'West',
                                  child: Text("West Zone"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section: Accessibility Tools
                  _buildSectionHeader("Accessibility Options", isDark),
                  _buildCard(
                    isDark: isDark,
                    child: Column(
                      children: [
                        // Wheelchair access switch
                        AccessibilityWrapper(
                          label: "Wheelchair assistance switch toggle",
                          isToggled: settings.wheelchairMode,
                          child: SwitchListTile(
                            secondary: Icon(
                              Icons.accessible,
                              color: AppColors.primaryContainer,
                            ),
                            title: const Text(
                              "Wheelchair Access Route Filter",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                              "Limits AI directions to routes with elevator corridors",
                            ),
                            value: settings.wheelchairMode,
                            activeColor: AppColors.primaryContainer,
                            onChanged: (value) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .toggleWheelchairMode();
                            },
                          ),
                        ),
                        const Divider(),

                        // Sensory friendly switch
                        AccessibilityWrapper(
                          label:
                              "Sensory-friendly quiet rooms mode switch toggle",
                          isToggled: settings.sensoryFriendlyMode,
                          child: SwitchListTile(
                            secondary: Icon(
                              Icons.volume_mute,
                              color: AppColors.secondary,
                            ),
                            title: const Text(
                              "Sensory-Friendly Mode",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                              "Informs assistant to prioritize quiet zones & sensory rooms",
                            ),
                            value: settings.sensoryFriendlyMode,
                            activeColor: AppColors.secondary,
                            onChanged: (value) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .toggleSensoryFriendlyMode();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section: General Settings
                  _buildSectionHeader("General Customization", isDark),
                  _buildCard(
                    isDark: isDark,
                    child: Column(
                      children: [
                        // Dark Mode switch
                        AccessibilityWrapper(
                          label: "Night mode theme toggle switch",
                          isToggled: isDark,
                          child: SwitchListTile(
                            secondary: Icon(
                              isDark ? Icons.dark_mode : Icons.light_mode,
                              color: isDark ? Colors.amber : Colors.grey,
                            ),
                            title: const Text(
                              "Night Mode (Dark UI Theme)",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                              "Toggles light and dark layouts matching Stitch designs",
                            ),
                            value: isDark,
                            activeColor: AppColors.primaryContainer,
                            onChanged: (value) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .toggleDarkMode();
                            },
                          ),
                        ),
                        const Divider(),
                        // Staff View Switch
                        AccessibilityWrapper(
                          label: "Staff and volunteer mode toggle switch",
                          isToggled: settings.staffModeEnabled,
                          child: SwitchListTile(
                            secondary: Icon(
                              Icons.admin_panel_settings,
                              color: settings.staffModeEnabled
                                  ? AppColors.primaryContainer
                                  : Colors.grey,
                            ),
                            title: const Text(
                              "Staff & Volunteer Dashboard Mode",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                              "Enables administrative metrics and operations AI chatbot",
                            ),
                            value: settings.staffModeEnabled,
                            activeColor: AppColors.primaryContainer,
                            onChanged: (value) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .toggleStaffMode();
                            },
                          ),
                        ),
                        const Divider(),

                        // Multilingual indicator listing
                        ListTile(
                          leading: Icon(
                            Icons.translate,
                            color: AppColors.primaryContainer,
                          ),
                          title: const Text(
                            "Multilingual Translation Assist",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            "Type in any language (Spanish, French, etc.) and StadiumGenie auto-detects and responds in kind.",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? BottomNavBar(
              activeRoute: '/settings',
              isDark: isDark,
              onNavigate: (route) =>
                  Navigator.pushReplacementNamed(context, route),
            )
          : null,
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 10.0),
      child: AccessibilityWrapper(
        label: "Settings section header: $title",
        header: true,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppColors.getOnSurfaceVariant(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, required bool isDark}) {
    return Card(
      color: AppColors.getSurfaceContainer(isDark),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.getOutline(isDark).withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: child,
      ),
    );
  }
}
