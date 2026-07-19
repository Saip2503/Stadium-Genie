import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stadium_data_model.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/side_nav_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../models/message_model.dart';

class StaffDashboardScreen extends ConsumerStatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  ConsumerState<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends ConsumerState<StaffDashboardScreen> {
  final List<MessageModel> _staffMessages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _staffMessages.add(
      MessageModel(
        id: MessageModel.generateId(),
        content: "🛠️ **StadiumGenie Operations Chat**\n\nI can assist you with operational scenarios, crowd redistribution recommendations, gate status adjustments, and volunteer routing. Try: *'How do we redistribute crowds from North to West?'* or *'What is the status of Gate A?'*",
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _sendStaffMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMsg = MessageModel(
      id: MessageModel.generateId(),
      content: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _staffMessages.add(userMsg);
      _isLoading = true;
    });

    _controller.clear();

    final aiRepository = ref.read(aiRepositoryProvider);
    final chatState = ref.read(chatProvider);
    final data = chatState.stadiumData;

    final String mockContext = data != null
        ? "Stadium: ${data.stadiumName}\nMatch: ${data.match}\nAlerts: ${data.alerts.map((a) => a.message).join(' | ')}"
        : "Stadium: FIFA 2026 MetLife Stadium";

    final systemPrompt = '''
You are StadiumGenie Operations, a dedicated assistant for FIFA 2026 stadium operators, venue managers, and volunteers.
Answer inquiries using operational terminology. Be concise and keep responses under 2-3 sentences.
Focus on: crowd density safety limits, dispatching volunteers to busy zones, and gate queue optimization.

DATA CONTEXT:
$mockContext
''';

    try {
      final stream = aiRepository.sendMessageStream(
        conversationHistory: _staffMessages,
        systemPrompt: systemPrompt,
      );

      final assistantMsgId = MessageModel.generateId();
      final loadingMsg = MessageModel(
        id: assistantMsgId,
        content: "",
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );

      setState(() {
        _staffMessages.add(loadingMsg);
      });

      String accumulated = "";
      await for (final chunk in stream) {
        accumulated += chunk;
        setState(() {
          final idx = _staffMessages.indexWhere((m) => m.id == assistantMsgId);
          if (idx != -1) {
            _staffMessages[idx] = _staffMessages[idx].copyWith(content: accumulated);
          }
        });
      }
    } catch (e) {
      setState(() {
        _staffMessages.add(
          MessageModel(
            id: MessageModel.generateId(),
            content: "Error communicating with operations node.",
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
          ),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = settings.isDarkMode;
    final chatState = ref.watch(chatProvider);
    final data = chatState.stadiumData;

    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width >= 900;

    if (!settings.staffModeEnabled) {
      return Scaffold(
        backgroundColor: AppColors.getBackground(isDark),
        appBar: AppBar(
          title: const Text("Access Denied"),
          backgroundColor: AppColors.getSurface(isDark),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                "Staff mode is currently disabled.",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text("Enable Staff View in Settings to unlock dashboard."),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/settings'),
                child: const Text("Go to Settings"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: AppColors.primaryContainer),
            const SizedBox(width: 8),
            Text(
              "Operations & Volunteers Control Room",
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
      ),
      body: Row(
        children: [
          if (isDesktop)
            SideNavBar(
              activeRoute: '/staff',
              isDark: isDark,
              onNavigate: (route) => Navigator.pushReplacementNamed(context, route),
            ),
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data != null) ...[
                      _buildAlertsSection(data, isDark),
                      const SizedBox(height: 24),
                      _buildMetricsGrid(data, isDark, isDesktop),
                      const SizedBox(height: 24),
                      _buildStaffChatPanel(isDark),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? BottomNavBar(
              activeRoute: '/staff',
              isDark: isDark,
              onNavigate: (route) => Navigator.pushReplacementNamed(context, route),
            )
          : null,
    );
  }

  Widget _buildAlertsSection(StadiumData data, bool isDark) {
    return Card(
      color: AppColors.getSurfaceContainer(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.getOutline(isDark).withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Text(
                  "ACTIVE SYSTEM ALERTS",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.getOnSurface(isDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (data.alerts.isEmpty)
              const Text("No active critical operational alerts.")
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.alerts.length,
                itemBuilder: (context, index) {
                  final alert = data.alerts[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      alert.severity == 'warning' ? Icons.warning : Icons.info,
                      color: alert.severity == 'warning' ? Colors.amber : Colors.blue,
                    ),
                    title: Text(alert.message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    trailing: Chip(
                      label: Text(alert.severity.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
                      backgroundColor: alert.severity == 'warning' ? Colors.amber : Colors.blue,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(StadiumData data, bool isDark, bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 16) / 2,
              child: _buildZonesCapacityCard(data, isDark),
            ),
            SizedBox(
              width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 16) / 2,
              child: _buildGatesStatusCard(data, isDark),
            ),
          ],
        );
      },
    );
  }

  Widget _buildZonesCapacityCard(StadiumData data, bool isDark) {
    return Card(
      color: AppColors.getSurfaceContainer(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.getOutline(isDark).withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ZONE OCCUPANCY LEVEL", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.getOnSurfaceVariant(isDark), fontSize: 12)),
            const SizedBox(height: 16),
            ...data.zones.entries.map((e) {
              final zone = e.value;
              final color = zone.crowdPercent > 80
                  ? Colors.red
                  : zone.crowdPercent > 50
                      ? Colors.amber
                      : Colors.green;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${e.key} Zone", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text("${zone.crowdPercent}% Capacity", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: zone.crowdPercent / 100,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGatesStatusCard(StadiumData data, bool isDark) {
    return Card(
      color: AppColors.getSurfaceContainer(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.getOutline(isDark).withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("GATES QUEUE STATUS", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.getOnSurfaceVariant(isDark), fontSize: 12)),
            const SizedBox(height: 16),
            ...data.gates.entries.map((e) {
              final gate = e.value;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.door_front_door,
                  color: gate.isOpen ? Colors.green : Colors.red,
                ),
                title: Text(gate.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text("Wait time: ${gate.queueMins} min"),
                trailing: Text(
                  gate.isOpen ? "OPEN" : "CLOSED",
                  style: TextStyle(
                    color: gate.isOpen ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffChatPanel(bool isDark) {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceContainer(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getOutline(isDark).withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _staffMessages.length,
              itemBuilder: (context, index) {
                final msg = _staffMessages[index];
                final isAssistant = msg.role == MessageRole.assistant;
                return Align(
                  alignment: isAssistant ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isAssistant
                          ? AppColors.getSurface(isDark)
                          : AppColors.primaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.getOnSurface(isDark),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Enter operational query...",
                    border: InputBorder.none,
                  ),
                  onSubmitted: _sendStaffMessage,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: AppColors.primaryContainer),
                onPressed: () => _sendStaffMessage(_controller.text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
