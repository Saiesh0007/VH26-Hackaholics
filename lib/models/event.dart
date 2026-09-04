enum WorkloadPriority {
  p0Payment,
  p0Order,
  p1Inventory,
  p2Activity,
  p3Log,
}

extension WorkloadPriorityX on WorkloadPriority {
  String get code {
    switch (this) {
      case WorkloadPriority.p0Payment:
        return 'P0';
      case WorkloadPriority.p0Order:
        return 'P0';
      case WorkloadPriority.p1Inventory:
        return 'P1';
      case WorkloadPriority.p2Activity:
        return 'P2';
      case WorkloadPriority.p3Log:
        return 'P3';
    }
  }

  String get displayName {
    switch (this) {
      case WorkloadPriority.p0Payment:
        return 'PAYMENT';
      case WorkloadPriority.p0Order:
        return 'ORDER';
      case WorkloadPriority.p1Inventory:
        return 'INVENTORY';
      case WorkloadPriority.p2Activity:
        return 'ACTIVITY';
      case WorkloadPriority.p3Log:
        return 'LOG';
    }
  }

  bool get isCritical =>
      this == WorkloadPriority.p0Payment || this == WorkloadPriority.p0Order;
}

enum ProcessingStrategy {
  stream,
  batch,
  defer,
  shed,
}

enum EventStatus {
  ingested,
  classified,
  queued,
  processing,
  processed,
  deferred,
  shed,
}

class PipelineEvent {
  final String id;
  final String type;
  final WorkloadPriority priority;
  final DateTime timestamp;
  final EventStatus status;
  final ProcessingStrategy strategy;
  final double latencyMs;
  final double queueTimeMs;
  final double processingTimeMs;
  final int payloadSizeBytes;
  final String workerId;
  final String decisionReason;

  const PipelineEvent({
    required this.id,
    required this.type,
    required this.priority,
    required this.timestamp,
    required this.status,
    required this.strategy,
    required this.latencyMs,
    required this.queueTimeMs,
    required this.processingTimeMs,
    required this.payloadSizeBytes,
    required this.workerId,
    required this.decisionReason,
  });

  PipelineEvent copyWith({
    String? id,
    String? type,
    WorkloadPriority? priority,
    DateTime? timestamp,
    EventStatus? status,
    ProcessingStrategy? strategy,
    double? latencyMs,
    double? queueTimeMs,
    double? processingTimeMs,
    int? payloadSizeBytes,
    String? workerId,
    String? decisionReason,
  }) {
    return PipelineEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      strategy: strategy ?? this.strategy,
      latencyMs: latencyMs ?? this.latencyMs,
      queueTimeMs: queueTimeMs ?? this.queueTimeMs,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      payloadSizeBytes: payloadSizeBytes ?? this.payloadSizeBytes,
      workerId: workerId ?? this.workerId,
      decisionReason: decisionReason ?? this.decisionReason,
    );
  }
}
