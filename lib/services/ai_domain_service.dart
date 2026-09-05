import 'package:dio/dio.dart';
import '../models/domain_policy.dart';
import '../core/constraints/policy_validator.dart';

class AiDomainService {
  final Dio dio;
  final String baseUrl;

  AiDomainService({
    Dio? dio,
    this.baseUrl = 'http://192.168.137.115:8000/api/v1',
  }) : dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 18),
            ));

  /// Generates a structured DomainPolicy via Backend (Gemini).
  /// Falls back deterministically if backend is unreachable or offline.
  Future<DomainPolicy> generatePolicy(String prompt) async {
    try {
      final response = await dio.post(
        '$baseUrl/ai/generate-policy',
        data: {'description': prompt},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final policy = DomainPolicy.fromJson(data);
        return policy;
      }
    } catch (_) {
      // Backend offline or Gemini failure - fallback deterministically
    }

    return _fallbackGeneratePolicy(prompt);
  }

  /// Deterministic local fallback generator for offline resiliency
  DomainPolicy _fallbackGeneratePolicy(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains('hospital') ||
        lower.contains('patient') ||
        lower.contains('ambulance') ||
        lower.contains('icu') ||
        lower.contains('disaster') ||
        lower.contains('medical')) {
      return DomainPolicy.hospital();
    } else if (lower.contains('education') ||
        lower.contains('student') ||
        lower.contains('result') ||
        lower.contains('exam') ||
        lower.contains('university') ||
        lower.contains('semester')) {
      return DomainPolicy.education();
    } else if (lower.contains('e-commerce') ||
        lower.contains('order') ||
        lower.contains('payment') ||
        lower.contains('cart')) {
      return DomainPolicy.ecommerce();
    }

    // Dynamic heuristic domain generator from prompt
    final domainWords = prompt.trim().split(RegExp(r'\s+'));
    final domainTitle = domainWords.isNotEmpty && domainWords.first.length > 2
        ? '${domainWords.first[0].toUpperCase()}${domainWords.first.substring(1)} Platform'
        : 'Custom Adaptive Domain';

    return DomainPolicy(
      domainName: domainTitle,
      description: prompt.trim().isEmpty
          ? 'Custom generated pipeline policy'
          : prompt.trim(),
      eventTypes: [
        const EventPolicy(
          name: 'Critical Alert',
          priority: 'P0',
          isCritical: true,
          slaMs: 150,
          preferredStrategy: 'stream',
          isBatchable: false,
          maxBatchSize: 1,
          canDefer: false,
          canShed: false,
          sheddingThreshold: 0.0,
          isRetryable: true,
          idempotencyRequired: true,
          processingCost: 1.0,
          dependencies: [],
          description: 'Top priority event with strict SLA guarantee',
        ),
        const EventPolicy(
          name: 'Core Transaction',
          priority: 'P1',
          isCritical: false,
          slaMs: 1500,
          preferredStrategy: 'micro_batch',
          isBatchable: true,
          maxBatchSize: 50,
          canDefer: false,
          canShed: false,
          sheddingThreshold: 0.0,
          isRetryable: true,
          idempotencyRequired: true,
          processingCost: 2.0,
          dependencies: [],
          description: 'Essential operational data',
        ),
        const EventPolicy(
          name: 'Status Update',
          priority: 'P2',
          isCritical: false,
          slaMs: 5000,
          preferredStrategy: 'micro_batch',
          isBatchable: true,
          maxBatchSize: 100,
          canDefer: true,
          canShed: false,
          sheddingThreshold: 0.0,
          isRetryable: true,
          idempotencyRequired: false,
          processingCost: 1.2,
          dependencies: [],
          description: 'Secondary status telemetry',
        ),
        const EventPolicy(
          name: 'Telemetry & Logs',
          priority: 'P3',
          isCritical: false,
          slaMs: 30000,
          preferredStrategy: 'batch',
          isBatchable: true,
          maxBatchSize: 500,
          canDefer: true,
          canShed: true,
          sheddingThreshold: 0.75,
          isRetryable: false,
          idempotencyRequired: false,
          processingCost: 0.5,
          dependencies: [],
          description: 'Volumetric telemetry that can be shed during pressure',
        ),
      ],
      priorityTiers: [
        const PriorityTier(
            code: 'P0',
            name: 'Critical Emergency',
            description: 'Immediate stream',
            targetSlaMs: 150),
        const PriorityTier(
            code: 'P1',
            name: 'Operational',
            description: 'High priority',
            targetSlaMs: 1500),
        const PriorityTier(
            code: 'P2',
            name: 'Standard',
            description: 'Micro-batchable',
            targetSlaMs: 5000),
        const PriorityTier(
            code: 'P3',
            name: 'Telemetry',
            description: 'Bulk batchable',
            targetSlaMs: 30000,
            allowShedding: true),
      ],
      globalSettings: const GlobalPolicySettings(
        maxQueueCapacity: 10000,
        baselineTrafficRate: 1000,
        spikeTrafficRate: 20000,
      ),
    );
  }

  /// Validates a policy using local deterministic rules first, then backend if available
  Future<PolicyValidationResult> validatePolicy(DomainPolicy policy) async {
    final localResult = DartPolicyValidator.validate(policy);
    if (!localResult.isValid) {
      return localResult;
    }

    try {
      final response = await dio.post(
        '$baseUrl/ai/validate-policy',
        data: {'policy': policy.toJson()},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final isValid = data['is_valid'] as bool? ?? true;
        final errors = (data['errors'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final warnings = (data['warnings'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        return PolicyValidationResult(
          isValid: isValid,
          errors: errors,
          warnings: warnings,
        );
      }
    } catch (_) {
      // Return local validation result if backend is unreachable
    }

    return localResult;
  }

  /// AI Copilot query with runtime pipeline context
  Future<Map<String, dynamic>> askCopilot({
    required String prompt,
    required DomainPolicy policy,
    required Map<String, dynamic> metrics,
    List<Map<String, dynamic>> recentDecisions = const [],
  }) async {
    try {
      final response = await dio.post(
        '$baseUrl/ai/copilot',
        data: {
          'prompt': prompt,
          'policy': policy.toJson(),
          'metrics': metrics,
          'recent_decisions': recentDecisions,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {}

    // Deterministic offline Copilot engine
    return _deterministicCopilotResponse(prompt, policy, metrics);
  }

  Map<String, dynamic> _deterministicCopilotResponse(
    String prompt,
    DomainPolicy policy,
    Map<String, dynamic> metrics,
  ) {
    final lower = prompt.toLowerCase();
    final queueDepth =
        metrics['total_queued_events'] ?? metrics['queue_depth'] ?? 0;
    final trafficRate =
        metrics['events_per_minute'] ?? metrics['traffic_rate'] ?? 1000;
    final workerCount =
        metrics['active_workers'] ?? metrics['worker_count'] ?? 8;
    final workerLoad =
        ((metrics['worker_utilization'] ?? 0.5) * 100).toStringAsFixed(1);
    final droppedCount = metrics['critical_events_dropped'] ?? 0;

    String facts;
    String currentMetrics;
    String policyInfo;
    String recommendation;

    if (lower.contains('batch') ||
        lower.contains('micro-batch') ||
        lower.contains('click')) {
      facts =
          'AdaptQ switches non-critical events from stream to micro-batch when queue depth exceeds safety thresholds.';
      currentMetrics =
          'Traffic is $trafficRate e/min. Queue depth is $queueDepth. Worker load is $workerLoad%.';
      policyInfo =
          'Active domain "${policy.domainName}" configures batchable events for P2/P3 tiers while guaranteeing stream processing for P0 critical events.';
      recommendation =
          'Maintain micro-batching for lower priority telemetry to prevent latency degradation on critical events.';
    } else if (lower.contains('defer') || lower.contains('delay')) {
      facts =
          'Event deferral buffers tolerant events in memory when queue pressure exceeds backpressure limits.';
      currentMetrics =
          'System currently running $workerCount workers under $trafficRate e/min rate.';
      policyInfo =
          'Events with canDefer=true and SLA > 5000ms are scheduled for deferred processing during peak intervals.';
      recommendation =
          'Once traffic falls below 5,000 e/min, deferred queues will be drained automatically without data loss.';
    } else if (lower.contains('shed') ||
        lower.contains('drop') ||
        lower.contains('log')) {
      facts =
          'Shedding drops only explicitly designated low-priority non-critical events to protect system stability.';
      currentMetrics =
          'Critical events dropped: $droppedCount (Zero tolerance). Total queue depth: $queueDepth.';
      policyInfo =
          'Policy strictly dictates: critical=true events have canShed=false and are NEVER shed.';
      recommendation =
          'Allow shedding on volatile telemetry during 20x spikes to protect SLA for life-critical/revenue-critical transactions.';
    } else if (lower.contains('scale') || lower.contains('worker')) {
      facts =
          'Dynamic worker autoscaling adjusts concurrency based on queue velocity and SLA time-to-expiry.';
      currentMetrics =
          'Current worker count: $workerCount. Worker utilization: $workerLoad%.';
      policyInfo =
          'Global settings allow max queue capacity of ${policy.globalSettings.maxQueueCapacity} and baseline ${policy.globalSettings.baselineTrafficRate} e/min.';
      recommendation = 'Worker allocation is optimal for current ingress rate.';
    } else {
      facts =
          'AdaptQ separates control plane policy intelligence from the high-throughput deterministic data plane.';
      currentMetrics =
          'Throughput: $trafficRate e/min. Queue depth: $queueDepth. Active workers: $workerCount.';
      policyInfo =
          'Active policy "${policy.domainName}" covers ${policy.eventTypes.length} distinct event types.';
      recommendation =
          'Use Chaos controls to test 20x spikes and observe real-time priority adaptations.';
    }

    return {
      'facts': facts,
      'current_metrics': currentMetrics,
      'policy': policyInfo,
      'recommendation': recommendation,
      'provider': 'Deterministic Fallback (Offline Mode)',
    };
  }

  /// AI / Deterministic Decision Explainability
  Future<Map<String, dynamic>> explainDecision({
    required Map<String, dynamic> event,
    required Map<String, dynamic> decision,
    required DomainPolicy policy,
    required Map<String, dynamic> metrics,
  }) async {
    try {
      final response = await dio.post(
        '$baseUrl/ai/explain-decision',
        data: {
          'event': event,
          'decision': decision,
          'policy': policy.toJson(),
          'metrics': metrics,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {}

    // Deterministic explainability
    final eventType = event['type']?.toString() ?? 'Generic Event';
    final priority = event['priority']?.toString() ?? 'P1';
    final isCritical = event['critical'] == true || priority == 'P0';
    final action = decision['action']?.toString() ?? 'STREAM';
    final slaMs = event['sla_ms'] ?? 1000;
    final queueDepth = metrics['total_queued_events'] ?? 2450;
    final workerLoad =
        ((metrics['worker_utilization'] ?? 0.65) * 100).toStringAsFixed(0);

    final reasons = <String>[];
    if (isCritical) {
      reasons.add('Critical event guarantee enforced by policy');
      reasons.add('Shedding and deferral strictly prohibited for $priority');
      reasons.add(
          'Target SLA is ${slaMs}ms; stream execution minimizes queuing delay');
    } else {
      reasons.add('Non-critical event category ($priority)');
      if (action.toUpperCase().contains('BATCH')) {
        reasons.add(
            'Queue pressure high ($queueDepth events); micro-batching improves throughput');
        reasons.add('SLA allows latency buffer (${slaMs}ms remaining)');
      } else if (action.toUpperCase().contains('SHED')) {
        reasons.add(
            'Queue overflow threshold exceeded; policy allows shedding for this tier');
        reasons.add(
            'Shedding active to preserve compute bandwidth for P0 critical streams');
      } else {
        reasons
            .add('Current worker load ($workerLoad%) allows direct processing');
      }
    }

    return {
      'event_id': event['id']?.toString() ?? 'EVT-001',
      'event_type': eventType,
      'priority': priority,
      'decision': action,
      'reasons': reasons,
      'metrics_snapshot': {
        'queue_depth': queueDepth,
        'worker_load': '$workerLoad%',
        'sla_ms': slaMs,
      },
    };
  }

  /// What-If Simulator with deterministic queueing simulation
  Future<Map<String, dynamic>> simulateWhatIf({
    required DomainPolicy policy,
    required double trafficRate,
    required int workers,
    double queueDepth = 0,
    int batchSize = 100,
  }) async {
    try {
      final response = await dio.post(
        '$baseUrl/ai/what-if',
        data: {
          'policy': policy.toJson(),
          'traffic_rate': trafficRate,
          'workers': workers,
          'queue_depth': queueDepth,
          'batch_size': batchSize,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {}

    // Deterministic simulation matching backend
    final workerCap = workers * 2500.0;
    final pressureRatio = trafficRate / (workerCap > 0 ? workerCap : 1.0);

    double p0Lat =
        45.0 + (pressureRatio > 1.0 ? (pressureRatio - 1.0) * 80.0 : 0.0);
    p0Lat = p0Lat > 250.0 ? 250.0 : p0Lat;

    double p1Lat = 180.0 * (1.0 + pressureRatio * 0.8);
    double p2Lat = 800.0 * (1.0 + pressureRatio * 1.5);
    double p3Lat = 3500.0 * (1.0 + pressureRatio * 3.0);

    double deferredPct = 0.0;
    double shedPct = 0.0;
    if (pressureRatio > 1.2) {
      deferredPct = ((pressureRatio - 1.0) * 20.0).clamp(0.0, 50.0);
      shedPct = ((pressureRatio - 1.5) * 25.0).clamp(0.0, 40.0);
    }

    final throughput = (trafficRate * (1.0 - (shedPct / 100.0))).round();
    final costPerHour = workers * 0.45 + (throughput / 10000.0) * 0.12;

    return {
      'predicted': {
        'p0_latency_ms': double.parse(p0Lat.toStringAsFixed(1)),
        'p1_latency_ms': double.parse(p1Lat.toStringAsFixed(1)),
        'p2_latency_ms': double.parse(p2Lat.toStringAsFixed(1)),
        'p3_latency_ms': double.parse(p3Lat.toStringAsFixed(1)),
        'deferred_percent': double.parse(deferredPct.toStringAsFixed(1)),
        'shed_percent': double.parse(shedPct.toStringAsFixed(1)),
        'critical_dropped': 0,
        'estimated_cost_per_hour': double.parse(costPerHour.toStringAsFixed(2)),
        'worker_utilization': (pressureRatio * 0.7).clamp(0.1, 1.0),
        'throughput_events_per_min': throughput,
      },
      'explanation':
          'Deterministic simulation: AdaptQ maintains 0 critical drops by batching P2 and shedding P3 under high pressure.',
    };
  }
}
