import 'event.dart';

class PriorityPolicy {
  final WorkloadPriority priority;
  final ProcessingStrategy mode;
  final int batchSize;
  final int deferWindowSeconds;
  final double samplingRate; // 1.0 = 100% processed, 0.2 = 80% shed
  final int workerCount;
  final bool backpressureEnabled;

  const PriorityPolicy({
    required this.priority,
    required this.mode,
    required this.batchSize,
    required this.deferWindowSeconds,
    required this.samplingRate,
    required this.workerCount,
    required this.backpressureEnabled,
  });

  PriorityPolicy copyWith({
    WorkloadPriority? priority,
    ProcessingStrategy? mode,
    int? batchSize,
    int? deferWindowSeconds,
    double? samplingRate,
    int? workerCount,
    bool? backpressureEnabled,
  }) {
    return PriorityPolicy(
      priority: priority ?? this.priority,
      mode: mode ?? this.mode,
      batchSize: batchSize ?? this.batchSize,
      deferWindowSeconds: deferWindowSeconds ?? this.deferWindowSeconds,
      samplingRate: samplingRate ?? this.samplingRate,
      workerCount: workerCount ?? this.workerCount,
      backpressureEnabled: backpressureEnabled ?? this.backpressureEnabled,
    );
  }
}

class PipelinePolicy {
  final Map<WorkloadPriority, PriorityPolicy> policies;
  final DateTime timestamp;
  final String version;
  final String reason;

  const PipelinePolicy({
    required this.policies,
    required this.timestamp,
    required this.version,
    required this.reason,
  });

  factory PipelinePolicy.defaultPolicy() {
    return PipelinePolicy(
      version: 'v1.0.0-default',
      reason: 'Baseline normal operation policy',
      timestamp: DateTime.now(),
      policies: {
        WorkloadPriority.p0Payment: const PriorityPolicy(
          priority: WorkloadPriority.p0Payment,
          mode: ProcessingStrategy.stream,
          batchSize: 1,
          deferWindowSeconds: 0,
          samplingRate: 1.0,
          workerCount: 8,
          backpressureEnabled: false,
        ),
        WorkloadPriority.p0Order: const PriorityPolicy(
          priority: WorkloadPriority.p0Order,
          mode: ProcessingStrategy.stream,
          batchSize: 1,
          deferWindowSeconds: 0,
          samplingRate: 1.0,
          workerCount: 8,
          backpressureEnabled: false,
        ),
        WorkloadPriority.p1Inventory: const PriorityPolicy(
          priority: WorkloadPriority.p1Inventory,
          mode: ProcessingStrategy.stream,
          batchSize: 50,
          deferWindowSeconds: 0,
          samplingRate: 1.0,
          workerCount: 4,
          backpressureEnabled: false,
        ),
        WorkloadPriority.p2Activity: const PriorityPolicy(
          priority: WorkloadPriority.p2Activity,
          mode: ProcessingStrategy.stream,
          batchSize: 100,
          deferWindowSeconds: 0,
          samplingRate: 1.0,
          workerCount: 2,
          backpressureEnabled: false,
        ),
        WorkloadPriority.p3Log: const PriorityPolicy(
          priority: WorkloadPriority.p3Log,
          mode: ProcessingStrategy.stream,
          batchSize: 250,
          deferWindowSeconds: 0,
          samplingRate: 1.0,
          workerCount: 1,
          backpressureEnabled: false,
        ),
      },
    );
  }
}
