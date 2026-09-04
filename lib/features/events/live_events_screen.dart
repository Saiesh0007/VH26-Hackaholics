import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/events_provider.dart';
import '../../models/event.dart';
import '../../widgets/event_tile.dart';
import '../../core/theme/app_colors.dart';
import 'event_trace_screen.dart';

class LiveEventsScreen extends ConsumerWidget {
  const LiveEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsStreamProvider);
    final priorityFilter = ref.watch(priorityFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LIVE EVENT STREAM', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('ALL', style: TextStyle(fontSize: 10)),
                    selected: priorityFilter == null,
                    onSelected: (_) => ref.read(priorityFilterProvider.notifier).state = null,
                    selectedColor: AppColors.info.withOpacity(0.2),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('P0 PAYMENTS', style: TextStyle(fontSize: 10)),
                    selected: priorityFilter == WorkloadPriority.p0Payment,
                    onSelected: (_) => ref.read(priorityFilterProvider.notifier).state = WorkloadPriority.p0Payment,
                    selectedColor: AppColors.p0Critical.withOpacity(0.2),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('P1 INVENTORY', style: TextStyle(fontSize: 10)),
                    selected: priorityFilter == WorkloadPriority.p1Inventory,
                    onSelected: (_) => ref.read(priorityFilterProvider.notifier).state = WorkloadPriority.p1Inventory,
                    selectedColor: AppColors.p1High.withOpacity(0.2),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('P2 ACTIVITY', style: TextStyle(fontSize: 10)),
                    selected: priorityFilter == WorkloadPriority.p2Activity,
                    onSelected: (_) => ref.read(priorityFilterProvider.notifier).state = WorkloadPriority.p2Activity,
                    selectedColor: AppColors.p2Normal.withOpacity(0.2),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('P3 LOGS', style: TextStyle(fontSize: 10)),
                    selected: priorityFilter == WorkloadPriority.p3Log,
                    onSelected: (_) => ref.read(priorityFilterProvider.notifier).state = WorkloadPriority.p3Log,
                    selectedColor: AppColors.p3Low.withOpacity(0.2),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                final filtered = priorityFilter == null
                    ? events
                    : events.where((e) => e.priority == priorityFilter).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No events matching selected priority filter.', style: TextStyle(color: AppColors.textMuted)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final event = filtered[index];
                    return EventTile(
                      event: event,
                      onTap: () {
                        ref.read(selectedEventProvider.notifier).state = event;
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => EventTraceScreen(event: event)),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, __) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
