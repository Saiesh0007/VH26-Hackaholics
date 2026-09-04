import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard/dashboard_screen.dart';
import 'events/live_events_screen.dart';
import 'flowmind/flowmind_screen.dart';
import 'pipeline/pipeline_screen.dart';
import 'insights/insights_screen.dart';
import 'simulator/simulator_screen.dart';
import 'benchmark/benchmark_screen.dart';
import 'incidents/incidents_screen.dart';
import 'shedding/load_shedding_screen.dart';
import 'settings/settings_screen.dart';
import 'demo/demo_banner.dart';
import '../core/theme/app_colors.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    LiveEventsScreen(),
    FlowMindScreen(),
    PipelineScreen(),
    InsightsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.background),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('PULSEFLOW', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  SizedBox(height: 4),
                  Text('Adaptive AI Data Pipeline', style: TextStyle(color: AppColors.agentGlow, fontSize: 11)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined, color: AppColors.info),
              title: const Text('Command Center', style: TextStyle(fontSize: 12)),
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.psychology_outlined, color: AppColors.agent),
              title: const Text('FlowMind Control Center', style: TextStyle(fontSize: 12)),
              onTap: () {
                setState(() => _currentIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune, color: AppColors.warning),
              title: const Text('What-If Simulator', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SimulatorScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.equalizer, color: AppColors.healthy),
              title: const Text('Naive vs Adaptive Benchmark', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BenchmarkScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.filter_alt_outlined, color: AppColors.critical),
              title: const Text('Controlled Load Shedding', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoadSheddingScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              title: const Text('Incident Center', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const IncidentsScreen()));
              },
            ),
            const Divider(color: AppColors.divider),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: AppColors.textMuted),
              title: const Text('Settings & Backend Config', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'COMMAND'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'EVENTS'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology_outlined), label: 'FLOWMIND'),
          BottomNavigationBarItem(icon: Icon(Icons.account_tree_outlined), label: 'PIPELINE'),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'INSIGHTS'),
        ],
      ),
    );
  }
}
