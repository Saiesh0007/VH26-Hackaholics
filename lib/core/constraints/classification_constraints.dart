import '../../models/event.dart';

/// Deterministic, zero-copy classification constraints.
/// Event classification is explicitly decoupled from AI agents, guaranteeing
/// sub-microsecond deterministic categorization based on domain constraints.
class ClassificationConstraints {
  /// Match event to priority tier using deterministic rule matrix.
  static WorkloadPriority classify({
    required String eventType,
    double? transactionValue,
    String? customerTier,
    Map<String, dynamic>? metadata,
  }) {
    final type = eventType.trim().toLowerCase();

    // Constraint Rule 1: High-value financial transactions & payments are ALWAYS P0
    if (type.contains('payment') ||
        type.contains('checkout') ||
        type.contains('charge') ||
        type.contains('refund') ||
        (transactionValue != null && transactionValue > 0)) {
      return WorkloadPriority.p0Payment;
    }

    // Constraint Rule 2: Order creations, fulfillment, and cancellations are P0
    if (type.contains('order') ||
        type.contains('purchase') ||
        type.contains('invoice')) {
      return WorkloadPriority.p0Order;
    }

    // Constraint Rule 3: Stock reservations, inventory locks, and warehouse sync are P1
    if (type.contains('inventory') ||
        type.contains('stock') ||
        type.contains('warehouse') ||
        type.contains('catalog') ||
        type.contains('sku')) {
      return WorkloadPriority.p1Inventory;
    }

    // Constraint Rule 4: User sessions, clickstream, page views, and cart actions are P2
    if (type.contains('activity') ||
        type.contains('click') ||
        type.contains('cart') ||
        type.contains('view') ||
        type.contains('session') ||
        type.contains('browse') ||
        type.contains('search')) {
      return WorkloadPriority.p2Activity;
    }

    // Constraint Rule 5: Debug logs, heartbeat, system audit traces are P3 (Low priority)
    return WorkloadPriority.p3Log;
  }

  /// Get human-readable constraint explanation for why an event was categorized.
  static String getConstraintReason(WorkloadPriority priority) {
    switch (priority) {
      case WorkloadPriority.p0Payment:
        return 'Constraint [FIN-01]: Financial transaction / payment webhook requires zero-drop guaranteed delivery.';
      case WorkloadPriority.p0Order:
        return 'Constraint [ORD-01]: Purchase order fulfillment requires strict FIFO latency SLA (<50ms).';
      case WorkloadPriority.p1Inventory:
        return 'Constraint [INV-02]: Inventory synchronization permits adaptive micro-batching under load.';
      case WorkloadPriority.p2Activity:
        return 'Constraint [ACT-03]: User behavioral telemetry permits temporary disk spillover deferral.';
      case WorkloadPriority.p3Log:
        return 'Constraint [LOG-04]: Debug telemetry permits controlled statistical sampling / shedding.';
    }
  }
}
