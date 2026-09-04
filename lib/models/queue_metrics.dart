import 'event.dart';

class PriorityQueueMetrics {
  final WorkloadPriority priority;
  final int queueDepth;
  final int capacity;
  final double latencyMs;
  final int throughputPerSec;
  final ProcessingStrategy activeStrategy;
  final String statusTrend; // e.g. 'STABLE', 'INCREASING', 'HIGH PRESSURE'

  const PriorityQueueMetrics({
    required this.priority,
    required this.queueDepth,
    required this.capacity,
    required this.latencyMs,
    required this.throughputPerSec,
    required this.activeStrategy,
    required this.statusTrend,
  });

  double get capacityPercentage =>
      capacity > 0 ? (queueDepth / capacity * 100).clamp(0, 100) : 0;
}
