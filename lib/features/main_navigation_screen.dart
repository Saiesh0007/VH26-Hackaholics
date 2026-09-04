import 'dart:async';
import 'package:flutter/material.dart';
import 'dashboard/dashboard_screen.dart';
import 'events/live_events_screen.dart';
import 'flowmind/flowmind_screen.dart';
import 'pipeline/pipeline_screen.dart';
import 'insights/insights_screen.dart';
import 'simulator/simulator_screen.dart';
import 'benchmark/benchmark_screen.dart';
import 'incidents/incidents_screen.dart';
import 'incidents/emergency_call_dialog.dart';
import 'shedding/load_shedding_screen.dart';
import 'settings/settings_screen.dart';
import 'demo/demo_banner.dart';
import 'voice/voice_assistant_dialog.dart';
import '../services/bland_ai_service.dart';
import '../core/theme/app_colors.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<BlandAiCallRecord>? _emergencyCallSub;
  bool _isCallDialogShowing = false;

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(onOpenDrawer: _openDrawer),
      LiveEventsScreen(onOpenDrawer: _openDrawer),
      FlowMindScreen(onOpenDrawer: _openDrawer),
      PipelineScreen(onOpenDrawer: _openDrawer),
      InsightsScreen(onOpenDrawer: _openDrawer),
    ];

    // Global listener for automatic incoming emergency calls
    _emergencyCallSub = BlandAiService().onEmergencyCall.listen((record) {
      if (!_isCallDialogShowing && mounted) {
        _isCallDialogShowing = true;
        EmergencyCallDialog.show(
          context,
          incidentTitle: 'UNRECOVERABLE PIPELINE EDGE CASE',
          reason: record.reason,
          p0LatencyMs: 148.5,
          trafficRate: 100000,
        ).then((_) {
          _isCallDialogShowing = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _emergencyCallSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.8)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.cardBorder, width: 1.2),
                      boxShadow: AppColors.blueGlowShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 46,
                        height: 46,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AdaptQ',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Adaptive Pipeline Intelligence',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                children: [
                  _buildDrawerTile(
                    icon: Icons.dashboard_rounded,
                    title: 'Command Center',
                    subtitle: 'Real-time telemetry & surge control',
                    isSelected: _currentIndex == 0,
                    onTap: () {
                      setState(() => _currentIndex = 0);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.psychology_rounded,
                    title: 'FlowMind Control Center',
                    subtitle: 'Optimizer & Evaluator Dual-Agent',
                    isSelected: _currentIndex == 2,
                    onTap: () {
                      setState(() => _currentIndex = 2);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.tune_rounded,
                    title: 'What-If Simulator',
                    subtitle: 'Simulate 20×-100× surge conditions',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SimulatorScreen()));
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.stacked_bar_chart_rounded,
                    title: 'Naive vs Adaptive Benchmark',
                    subtitle: 'Direct SLA & latency comparison',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const BenchmarkScreen()));
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.filter_alt_rounded,
                    title: 'Controlled Load Shedding',
                    subtitle: 'Zero-drop P0, deterministic P3 drop',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoadSheddingScreen()));
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.warning_amber_rounded,
                    title: 'Incident Center',
                    subtitle: 'Bland AI Voice Dispatch & In-App Call',
                    badge: 'BLAND AI',
                    badgeColor: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const IncidentsScreen()));
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    child: Divider(color: AppColors.divider),
                  ),
                  _buildDrawerTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings & Backend Config',
                    subtitle: 'Thresholds, API keys & SLAs',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const DemoNarratorBanner(),
          Expanded(child: _pages[_currentIndex]),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: AppColors.orangeGlowShadow,
        ),
        child: FloatingActionButton(
          onPressed: () => VoiceAssistantDialog.show(context),
          backgroundColor: AppColors.primary,
          elevation: 6,
          tooltip: 'Ask FlowMind',
          shape: const CircleBorder(),
          child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder, width: 0.8),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
                _buildNavItem(1, Icons.list_alt_rounded, 'Events'),
                _buildNavItem(2, Icons.psychology_rounded, 'FlowMind'),
                _buildNavItem(3, Icons.account_tree_rounded, 'Pipeline'),
                _buildNavItem(4, Icons.insights_rounded, 'Analytics'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    String? subtitle,
    String? badge,
    Color? badgeColor,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppColors.primaryLight : AppColors.cardBorder,
              width: 0.8,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              )
            : null,
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (badgeColor ?? AppColors.primary).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: (badgeColor ?? AppColors.primary).withOpacity(0.6),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor ?? AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
