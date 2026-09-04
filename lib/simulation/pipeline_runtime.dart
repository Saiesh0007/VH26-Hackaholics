import 'dart:math';
import '../models/event.dart';
import '../models/pipeline_metrics.dart';
import '../models/queue_metrics.dart';
import '../models/pipeline_policy.dart';
import '../core/constants/app_constants.dart';
import '../core/constraints/classification_constraints.dart';

class PipelineRuntime {
  final Random _random = Random();

  PipelinePolicy _activePolicy = PipelinePolicy.defaultPolicy();
  int _trafficRatePerMin = AppConstants.normalTrafficRate;
  
  // Internal Queue Depths
  final Map<WorkloadPriority, int> _queueDepths = {
    WorkloadPriority.p0Payment: 12,
    WorkloadPriority.p0Order: 15,
    WorkloadPriority.p1Inventory: 45,
    WorkloadPriority.p2Activity: 120,
    WorkloadPriority.p3Log: 350,
  };

  final List<PipelineEvent> _recentEvents = [];
  int _totalDeferredCount = 0;
  int _totalShedCount = 0;
  int _criticalEventsLost = 0;
  int _eventCounter = 1000;

  PipelinePolicy get activePolicy => _activePolicy;
  int get trafficRate => _trafficRatePerMin;
  List<PipelineEvent> get recentEvents => List.unmodifiable(_recentEvents);

  void setTrafficRate(int ratePerMin) {
    _trafficRatePerMin = ratePerMin;
  }

  void setPolicy(PipelinePolicy policy) {
    _activePolicy = policy;
  }

  /// Simulation Step - Executed on periodic tick (e.g. 1 sec tick)
  PipelineMetrics tickSimulation() {
    final eventsPerSec = (_trafficRatePerMin / 60.0).round() + _random.nextInt(5) - 2;
    final clampedEventsPerSec = max(10, eventsPerSec);

    // 1. Generate Ingestion Workload & Enqueue based on Policy
    for (int i = 0; i < clampedEventsPerSec; i++) {
      final priority = _classifyIncomingEvent();
      final policy = _activePolicy.policies[priority] ??
          PriorityPolicy(
            priority: priority,
            mode: ProcessingStrategy.stream,
            batchSize: 1,
            deferWindowSeconds: 0,
            samplingRate: 1.0,
            workerCount: 2,
            backpressureEnabled: false,
          );

      // Check Load Shedding for Non-Critical workloads under sampling
      if (!priority.isCritical && policy.samplingRate < 1.0) {
        if (_random.nextDouble() > policy.samplingRate) {
          _totalShedCount++;
          _addRecentEvent(
            priority: priority,
            status: EventStatus.shed,
            strategy: ProcessingStrategy.shed,
            latencyMs: 0.0,
            decisionReason: 'Shed non-critical workload under sampling policy (${(policy.samplingRate * 100).toInt()}% retained)',
          );
          continue; // Skip enqueueing
        }
      }

      // Deferral logic
      if (policy.mode == ProcessingStrategy.defer) {
        _totalDeferredCount++;
        _queueDepths[priority] = min(AppConstants.maxQueueCapacity, (_queueDepths[priority] ?? 0) + 1);
        _addRecentEvent(
          priority: priority,
          status: EventStatus.deferred,
          strategy: ProcessingStrategy.defer,
          latencyMs: 250.0 + _random.nextInt(300),
          decisionReason: 'Intentionally deferred processing to relieve system pressure',
        );
      } else {
        // Enqueue for processing
        _queueDepths[priority] = min(AppConstants.maxQueueCapacity, (_queueDepths[priority] ?? 0) + 1);
      }
    }

    // 2. Process Queues with Worker Capacity & Active Strategy
    int totalThroughputSec = 0;
    double p0LatencySum = 0;
    int p0ProcessedCount = 0;

    for (final priority in WorkloadPriority.values) {
      final depth = _queueDepths[priority] ?? 0;
      if (depth <= 0) continue;

      final policy = _activePolicy.policies[priority]!;
      int workerCapacity = policy.workerCount * (policy.mode == ProcessingStrategy.batch ? policy.batchSize : 15);
      
      int processed = min(depth, workerCapacity);
      _queueDepths[priority] = depth - processed;
      totalThroughputSec += processed;

      // Calculate Latency & simulate processed event stream
      final queueFactor = (depth / 500.0).clamp(0.0, 10.0);
      final latency = (priority.isCritical ? 15.0 : 40.0) + (queueFactor * 12.0) + (_random.nextDouble() * 10.0);

      if (priority.isCritical) {
        p0LatencySum += latency;
        p0ProcessedCount++;
      }

      if (processed > 0 && _random.nextDouble() > 0.4) {
        _addRecentEvent(
          priority: priority,
          status: EventStatus.processed,
          strategy: policy.mode,
          latencyMs: latency,
          decisionReason: priority.isCritical
              ? 'Critical workload + immediate latency target guaranteed by SafetyGuard'
              : 'Processed under adaptive mode (${policy.mode.name.toUpperCase()})',
        );
      }
    }

    // 3. Compute Metrics
    final totalQueueDepth = _queueDepths.values.fold(0, (a, b) => a + b);
    final queuePressure = (totalQueueDepth / (AppConstants.maxQueueCapacity * 0.2) * 100).clamp(0.0, 100.0);
    final systemLoad = ((_trafficRatePerMin / AppConstants.spikeTrafficRate) * 75.0 + (queuePressure * 0.25)).clamp(15.0, 99.0);
    final avgP0Latency = p0ProcessedCount > 0 ? (p0LatencySum / p0ProcessedCount) : 38.5;

    return PipelineMetrics(
      eventRatePerMin: _trafficRatePerMin,
      throughputPerSec: totalThroughputSec,
      systemLoadPercentage: systemLoad,
      queuePressurePercentage: queuePressure,
      p0LatencyMs: avgP0Latency,
      p1LatencyMs: avgP0Latency * 1.4,
      p2LatencyMs: avgP0Latency * 2.8 + (queuePressure * 1.5),
      p3LatencyMs: avgP0Latency * 4.5 + (queuePressure * 4.0),
      criticalEventsLost: _criticalEventsLost, // ALWAYS 0
      totalDeferredCount: _totalDeferredCount,
      totalShedCount: _totalShedCount,
      workerUtilization: systemLoad > 80 ? 92.0 + (_random.nextDouble() * 6.0) : 45.0 + (_random.nextDouble() * 15.0),
      timestamp: DateTime.now(),
    );
  }

  List<PriorityQueueMetrics> getQueueMetricsList(PipelineMetrics metrics) {
    return WorkloadPriority.values.map((priority) {
      final depth = _queueDepths[priority] ?? 0;
      final policy = _activePolicy.policies[priority]!;
      final latency = priority.isCritical
          ? metrics.p0LatencyMs
          : (priority == WorkloadPriority.p1Inventory
              ? metrics.p1LatencyMs
              : (priority == WorkloadPriority.p2Activity ? metrics.p2LatencyMs : metrics.p3LatencyMs));

      String trend = 'STABLE';
      if (depth > 2000) trend = 'HIGH PRESSURE';
      else if (depth > 500) trend = 'BUILDING';

      return PriorityQueueMetrics(
        priority: priority,
        queueDepth: depth,
        capacity: AppConstants.maxQueueCapacity ~/ 4,
        latencyMs: latency,
        throughputPerSec: (metrics.throughputPerSec * (priority.isCritical ? 0.35 : 0.2)).round(),
        activeStrategy: policy.mode,
        statusTrend: trend,
      );
    }).toList();
  }

  WorkloadPriority _classifyIncomingEvent() {
    final roll = _random.nextDouble();
    String eventType;
    double? transactionValue;

    if (roll < 0.15) {
      eventType = 'payment.webhook.charge';
      transactionValue = 49.99 + _random.nextInt(500);
    } else if (roll < 0.30) {
      eventType = 'order.fulfillment.created';
      transactionValue = 29.99;
    } else if (roll < 0.50) {
      eventType = 'inventory.warehouse.sync';
    } else if (roll < 0.75) {
      eventType = 'activity.user.clickstream';
    } else {
      eventType = 'system.telemetry.debug_log';
    }

    // Deterministic constraint-based classification decoupled from AI agents:
    return ClassificationConstraints.classify(
      eventType: eventType,
      transactionValue: transactionValue,
    );
  }

  void _addRecentEvent({
    required WorkloadPriority priority,
    required EventStatus status,
    required ProcessingStrategy strategy,
    required double latencyMs,
    required String decisionReason,
  }) {
    _eventCounter++;
    final prefix = priority.displayName.substring(0, min(3, priority.displayName.length)).toUpperCase();
    final event = PipelineEvent(
      id: '#$prefix-$_eventCounter',
      type: priority.displayName,
      priority: priority,
      timestamp: DateTime.now(),
      status: status,
      strategy: strategy,
      latencyMs: latencyMs,
      queueTimeMs: (latencyMs * 0.3),
      processingTimeMs: (latencyMs * 0.7),
      payloadSizeBytes: priority.isCritical ? 1024 : 512,
      workerId: 'worker-${_random.nextInt(8) + 1}',
      decisionReason: decisionReason,
    );

    _recentEvents.insert(0, event);
    if (_recentEvents.length > AppConstants.maxEventHistorySize) {
      _recentEvents.removeLast();
    }
  }
}
