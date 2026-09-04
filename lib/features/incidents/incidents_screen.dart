import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pipeline_provider.dart';
import '../../models/incident.dart';
import '../../core/theme/app_colors.dart';

class IncidentsScreen extends ConsumerWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(pipelineRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('INCIDENT CENTER', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<SystemIncident>>(
        future: repo.getIncidents(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final incidents = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: incidents.length,
            itemBuilder: (context, index) {
              final inc = incidents[index];
              Color color;
              switch (inc.severity) {
                case IncidentSeverity.critical:
                  color = AppColors.critical;
                  break;
                case IncidentSeverity.warning:
                  color = AppColors.warning;
                  break;
                default:
                  color = AppColors.healthy;
                  break;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(inc.title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                          child: Text(inc.status, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(inc.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 8),
                    Text(inc.timestamp.toIso8601String().substring(11, 19), style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
