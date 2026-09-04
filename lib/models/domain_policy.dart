import 'dart:convert';
import 'event.dart';
import 'pipeline_policy.dart';

class EventPolicy {
  final String type;
  final String displayName;
  final String description;
  final String priority; // 'P0', 'P1', 'P2', 'P3'
  final bool critical;
  final int slaMs;
  final bool batchable;
  final int maxBatchSize;
  final String preferredStrategy; // 'stream', 'batch', 'defer', 'shed'
  final bool canDefer;
  final bool canShed;
  final double sheddingThreshold;
  final bool retryable;
  final bool idempotencyRequired;
  final double processingCost;
  final List<String> dependencies;

  String get name => displayName.isNotEmpty ? displayName : type;
  bool get isCritical => critical;
  bool get isBatchable => batchable;
  bool get isRetryable => retryable;

  const EventPolicy({
    String? type,
    String? displayName,
    String? name,
    this.description = '',
    required this.priority,
    bool? critical,
    bool? isCritical,
    required this.slaMs,
    bool? batchable,
    bool? isBatchable,
    this.maxBatchSize = 1,
    this.preferredStrategy = 'stream',
    this.canDefer = false,
    this.canShed = false,
    this.sheddingThreshold = 0.0,
    bool? retryable,
    bool? isRetryable,
    this.idempotencyRequired = true,
    this.processingCost = 0.5,
    this.dependencies = const [],
  })  : type = type ?? name ?? 'event',
        displayName = displayName ?? name ?? type ?? 'event',
        critical = critical ?? isCritical ?? false,
        batchable = batchable ?? isBatchable ?? false,
        retryable = retryable ?? isRetryable ?? true;

  EventPolicy copyWith({
    String? type,
    String? displayName,
    String? name,
    String? description,
    String? priority,
    bool? critical,
    bool? isCritical,
    int? slaMs,
    bool? batchable,
    bool? isBatchable,
    int? maxBatchSize,
    String? preferredStrategy,
    bool? canDefer,
    bool? canShed,
    double? sheddingThreshold,
    bool? retryable,
    bool? isRetryable,
    bool? idempotencyRequired,
    double? processingCost,
    List<String>? dependencies,
  }) {
    return EventPolicy(
      type: type ?? this.type,
      displayName: displayName ?? name ?? this.displayName,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      critical: critical ?? isCritical ?? this.critical,
      slaMs: slaMs ?? this.slaMs,
      batchable: batchable ?? isBatchable ?? this.batchable,
      maxBatchSize: maxBatchSize ?? this.maxBatchSize,
      preferredStrategy: preferredStrategy ?? this.preferredStrategy,
      canDefer: canDefer ?? this.canDefer,
      canShed: canShed ?? this.canShed,
      sheddingThreshold: sheddingThreshold ?? this.sheddingThreshold,
      retryable: retryable ?? isRetryable ?? this.retryable,
      idempotencyRequired: idempotencyRequired ?? this.idempotencyRequired,
      processingCost: processingCost ?? this.processingCost,
      dependencies: dependencies ?? this.dependencies,
    );
  }

  WorkloadPriority toWorkloadPriority() {
    switch (priority) {
      case 'P0':
        return type.contains('order') ? WorkloadPriority.p0Order : WorkloadPriority.p0Payment;
      case 'P1':
        return WorkloadPriority.p1Inventory;
      case 'P2':
        return WorkloadPriority.p2Activity;
      case 'P3':
      default:
        return WorkloadPriority.p3Log;
    }
  }

  ProcessingStrategy get parsedPreferredStrategy {
    switch (preferredStrategy.toLowerCase()) {
      case 'batch':
        return ProcessingStrategy.batch;
      case 'defer':
        return ProcessingStrategy.defer;
      case 'shed':
        return ProcessingStrategy.shed;
      case 'stream':
      default:
        return ProcessingStrategy.stream;
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'displayName': displayName,
        'description': description,
        'priority': priority,
        'critical': critical,
        'slaMs': slaMs,
        'batchable': batchable,
        'maxBatchSize': maxBatchSize,
        'preferredStrategy': preferredStrategy,
        'canDefer': canDefer,
        'canShed': canShed,
        'sheddingThreshold': sheddingThreshold,
        'retryable': retryable,
        'idempotencyRequired': idempotencyRequired,
        'processingCost': processingCost,
        'dependencies': dependencies,
      };

  factory EventPolicy.fromJson(Map<String, dynamic> json) => EventPolicy(
        type: json['type'] as String? ?? 'event.unknown',
        displayName: json['displayName'] as String? ?? json['type'] as String? ?? 'Unknown',
        description: json['description'] as String? ?? '',
        priority: json['priority'] as String? ?? 'P2',
        critical: json['critical'] as bool? ?? false,
        slaMs: json['slaMs'] as int? ?? 500,
        batchable: json['batchable'] as bool? ?? false,
        maxBatchSize: json['maxBatchSize'] as int? ?? 1,
        preferredStrategy: json['preferredStrategy'] as String? ?? 'stream',
        canDefer: json['canDefer'] as bool? ?? false,
        canShed: json['canShed'] as bool? ?? false,
        sheddingThreshold: (json['sheddingThreshold'] as num?)?.toDouble() ?? 0.0,
        retryable: json['retryable'] as bool? ?? true,
        idempotencyRequired: json['idempotencyRequired'] as bool? ?? false,
        processingCost: (json['processingCost'] as num?)?.toDouble() ?? 0.5,
        dependencies: (json['dependencies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

class PriorityTier {
  final String code;
  final String name;
  final String description;
  final int targetSlaMs;
  final bool allowShedding;

  const PriorityTier({
    required this.code,
    required this.name,
    required this.description,
    required this.targetSlaMs,
    this.allowShedding = false,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'description': description,
        'targetSlaMs': targetSlaMs,
        'allowShedding': allowShedding,
      };

  factory PriorityTier.fromJson(Map<String, dynamic> json) => PriorityTier(
        code: json['code'] as String? ?? 'P2',
        name: json['name'] as String? ?? 'Standard Tier',
        description: json['description'] as String? ?? '',
        targetSlaMs: json['targetSlaMs'] as int? ?? 2000,
        allowShedding: json['allowShedding'] as bool? ?? false,
      );
}

class GlobalPolicySettings {
  final int baselineTrafficRate;
  final int spikeTrafficRate;
  final int maxQueueCapacity;
  final int maxBatchSizeLimit;
  final int maxDeferWindowSecondsLimit;
  final double maxSamplingRateLimit;

  const GlobalPolicySettings({
    this.baselineTrafficRate = 1000,
    this.spikeTrafficRate = 20000,
    this.maxQueueCapacity = 10000,
    this.maxBatchSizeLimit = 1000,
    this.maxDeferWindowSecondsLimit = 300,
    this.maxSamplingRateLimit = 0.90,
  });

  Map<String, dynamic> toJson() => {
        'baselineTrafficRate': baselineTrafficRate,
        'spikeTrafficRate': spikeTrafficRate,
        'maxQueueCapacity': maxQueueCapacity,
        'maxBatchSizeLimit': maxBatchSizeLimit,
        'maxDeferWindowSecondsLimit': maxDeferWindowSecondsLimit,
        'maxSamplingRateLimit': maxSamplingRateLimit,
      };

  factory GlobalPolicySettings.fromJson(Map<String, dynamic> json) => GlobalPolicySettings(
        baselineTrafficRate: json['baselineTrafficRate'] as int? ?? 1000,
        spikeTrafficRate: json['spikeTrafficRate'] as int? ?? 20000,
        maxQueueCapacity: json['maxQueueCapacity'] as int? ?? 10000,
        maxBatchSizeLimit: json['maxBatchSizeLimit'] as int? ?? 1000,
        maxDeferWindowSecondsLimit: json['maxDeferWindowSecondsLimit'] as int? ?? 300,
        maxSamplingRateLimit: (json['maxSamplingRateLimit'] as num?)?.toDouble() ?? 0.90,
      );
}

class DomainPolicy {
  final String domainName;
  final String description;
  final String version;
  final List<EventPolicy> eventTypes;
  final List<PriorityTier> priorityTiers;
  final GlobalPolicySettings globalSettings;

  const DomainPolicy({
    required this.domainName,
    required this.description,
    this.version = 'v1.0.0',
    required this.eventTypes,
    this.priorityTiers = const [],
    this.globalSettings = const GlobalPolicySettings(),
  });

  /// Convert DomainPolicy into operational PipelinePolicy for runtime
  PipelinePolicy toPipelinePolicy() {
    final Map<WorkloadPriority, PriorityPolicy> policies = {};

    // Defaults for standard slots
    for (final priority in WorkloadPriority.values) {
      policies[priority] = PriorityPolicy(
        priority: priority,
        mode: priority.isCritical ? ProcessingStrategy.stream : ProcessingStrategy.batch,
        batchSize: priority.isCritical ? 1 : 50,
        deferWindowSeconds: 0,
        samplingRate: 1.0,
        workerCount: priority.isCritical ? 8 : 4,
        backpressureEnabled: false,
      );
    }

    // Map each EventPolicy to matching priority tier
    for (final event in eventTypes) {
      final p = event.toWorkloadPriority();
      final current = policies[p]!;
      policies[p] = current.copyWith(
        mode: event.parsedPreferredStrategy,
        batchSize: event.batchable ? event.maxBatchSize : 1,
        samplingRate: event.canShed ? (1.0 - event.sheddingThreshold).clamp(0.1, 1.0) : 1.0,
      );
    }

    return PipelinePolicy(
      version: version,
      reason: 'Active Domain: $domainName',
      timestamp: DateTime.now(),
      policies: policies,
    );
  }

  Map<String, dynamic> toJson() => {
        'domainName': domainName,
        'description': description,
        'version': version,
        'eventTypes': eventTypes.map((e) => e.toJson()).toList(),
        'priorityTiers': priorityTiers.map((e) => e.toJson()).toList(),
        'globalSettings': globalSettings.toJson(),
      };

  factory DomainPolicy.fromJson(Map<String, dynamic> json) => DomainPolicy(
        domainName: json['domainName'] as String? ?? 'Custom Domain',
        description: json['description'] as String? ?? '',
        version: json['version'] as String? ?? 'v1.0.0',
        eventTypes: (json['eventTypes'] as List<dynamic>?)
                ?.map((e) => EventPolicy.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        priorityTiers: (json['priorityTiers'] as List<dynamic>?)
                ?.map((e) => PriorityTier.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        globalSettings: json['globalSettings'] != null
            ? GlobalPolicySettings.fromJson(json['globalSettings'] as Map<String, dynamic>)
            : const GlobalPolicySettings(),
      );

  // -------------------------------------------------------------
  // Built-in Predefined Domain Policies
  // -------------------------------------------------------------

  static DomainPolicy ecommerce() => const DomainPolicy(
        domainName: 'E-Commerce Flash Sale',
        description: 'Adaptive e-commerce event pipeline protecting P0 payments & orders during traffic surges.',
        version: 'v1.0.0',
        eventTypes: [
          EventPolicy(
            type: 'payment.webhook.charge',
            displayName: 'Payment Webhook',
            description: 'Financial transactions & checkout capture',
            priority: 'P0',
            critical: true,
            slaMs: 50,
            batchable: false,
            maxBatchSize: 1,
            preferredStrategy: 'stream',
            canDefer: false,
            canShed: false,
            retryable: true,
            idempotencyRequired: true,
            processingCost: 0.7,
          ),
          EventPolicy(
            type: 'order.fulfillment.created',
            displayName: 'Order Fulfillment',
            description: 'Order reservation and fulfillment queues',
            priority: 'P0',
            critical: true,
            slaMs: 100,
            batchable: false,
            maxBatchSize: 1,
            preferredStrategy: 'stream',
            canDefer: false,
            canShed: false,
            retryable: true,
            idempotencyRequired: true,
            processingCost: 0.8,
          ),
          EventPolicy(
            type: 'inventory.warehouse.sync',
            displayName: 'Inventory Sync',
            description: 'Warehouse stock updates & allocations',
            priority: 'P1',
            critical: false,
            slaMs: 2000,
            batchable: true,
            maxBatchSize: 100,
            preferredStrategy: 'batch',
            canDefer: false,
            canShed: false,
            retryable: true,
            idempotencyRequired: true,
            processingCost: 0.5,
          ),
          EventPolicy(
            type: 'activity.user.clickstream',
            displayName: 'User Clickstream',
            description: 'Browsing telemetry & cart modifications',
            priority: 'P2',
            critical: false,
            slaMs: 10000,
            batchable: true,
            maxBatchSize: 250,
            preferredStrategy: 'defer',
            canDefer: true,
            canShed: false,
            retryable: false,
            idempotencyRequired: false,
            processingCost: 0.3,
          ),
          EventPolicy(
            type: 'system.telemetry.debug_log',
            displayName: 'Telemetry & Logs',
            description: 'Debug metrics, traces, and worker logs',
            priority: 'P3',
            critical: false,
            slaMs: 30000,
            batchable: true,
            maxBatchSize: 500,
            preferredStrategy: 'shed',
            canDefer: true,
            canShed: true,
            sheddingThreshold: 0.70,
            retryable: false,
            idempotencyRequired: false,
            processingCost: 0.2,
          ),
        ],
        priorityTiers: [
          PriorityTier(code: 'P0', name: 'Critical Financial', description: 'Immediate streaming. Zero loss.', targetSlaMs: 50),
          PriorityTier(code: 'P1', name: 'High Inventory', description: 'Adaptive micro-batching under load.', targetSlaMs: 2000),
          PriorityTier(code: 'P2', name: 'Normal Activity', description: 'Spillover disk deferral.', targetSlaMs: 10000),
          PriorityTier(code: 'P3', name: 'Low Telemetry', description: 'Statistical sampling allowed.', targetSlaMs: 30000, allowShedding: true),
        ],
      );

  static DomainPolicy hospital() => const DomainPolicy(
        domainName: 'Hospital Disaster Management',
        description: 'Mass casualty trauma triage & emergency life-safety coordination pipeline.',
        version: 'v1.0.0',
        eventTypes: [
          EventPolicy(
            type: 'emergency.patient.alert',
            displayName: 'Patient Emergency Alert',
            description: 'Critical vitals, trauma arrest, and resuscitation alerts',
            priority: 'P0',
            critical: true,
            slaMs: 50,
            batchable: false,
            maxBatchSize: 1,
            preferredStrategy: 'stream',
            canDefer: false,
            canShed: false,
            retryable: true,
            idempotencyRequired: true,
            processingCost: 0.9,
          ),
          EventPolicy(
            type: 'ambulance.arrival.triage',
            displayName: 'Ambulance Arrival',
            description: 'Inbound paramedic triage telemetry',
            priority: 'P0',
            critical: true,
            slaMs: 100,
            batchable: false,
            maxBatchSize: 1,
            preferredStrategy: 'stream',
            canDefer: false,
            canShed: false,
            retryable: true,
            idempotencyRequired: true,
            processingCost: 0.8,
          ),
          EventPolicy(
            type: 'icu.bed.status',
            displayName: 'ICU Bed Availability',
            description: 'Operating room and ICU bed reservation sync',
            priority: 'P1',
            critical: false,
            slaMs: 1500,
            batchable: true,
            maxBatchSize: 50,
            preferredStrategy: 'batch',
            canDefer: false,
            canShed: false,
            retryable: true,
            idempotencyRequired: true,
            processingCost: 0.5,
          ),
          EventPolicy(
            type: 'medical.inventory.blood_units',
            displayName: 'Blood & Med Inventory',
            description: 'Emergency blood units, plasma, and oxygen supplies',
            priority: 'P1',
            critical: false,
            slaMs: 2000,
            batchable: true,
            maxBatchSize: 100,
            preferredStrategy: 'batch',
            canDefer: false,
            canShed: false,
            retryable: true,
            idempotencyRequired: true,
            processingCost: 0.5,
          ),
          EventPolicy(
            type: 'doctor.shift.notifications',
            displayName: 'Staff Shift Alert',
            description: 'Doctor on-call rotation notices',
            priority: 'P2',
            critical: false,
            slaMs: 8000,
            batchable: true,
            maxBatchSize: 200,
            preferredStrategy: 'defer',
            canDefer: true,
            canShed: false,
            retryable: false,
            idempotencyRequired: false,
            processingCost: 0.4,
          ),
          EventPolicy(
            type: 'hospital.analytics.reports',
            displayName: 'Facility Telemetry',
            description: 'Sensor data, shift statistics, and diagnostic archives',
            priority: 'P3',
            critical: false,
            slaMs: 30000,
            batchable: true,
            maxBatchSize: 500,
            preferredStrategy: 'shed',
            canDefer: true,
            canShed: true,
            sheddingThreshold: 0.75,
            retryable: false,
            idempotencyRequired: false,
            processingCost: 0.2,
          ),
        ],
        priorityTiers: [
          PriorityTier(code: 'P0', name: 'Critical Trauma Alert', description: 'Zero loss streaming.', targetSlaMs: 50),
          PriorityTier(code: 'P1', name: 'High ICU & Inventory', description: 'Micro-batched updates.', targetSlaMs: 2000),
          PriorityTier(code: 'P2', name: 'Normal Staff Alerts', description: 'Spillover buffer during surge.', targetSlaMs: 8000),
          PriorityTier(code: 'P3', name: 'Low Diagnostics', description: 'Sampled during extreme load.', targetSlaMs: 30000, allowShedding: true),
        ],
      );

  static DomainPolicy education() => const DomainPolicy(
        domainName: 'Education / Result Publishing',
        description: 'Semester result publishing with 100,000+ concurrent student queries.',
        version: 'v1.0.0',
        eventTypes: [
          EventPolicy(
            type: 'result.lookup.query',
            displayName: 'Result Scorecard Query',
            description: 'Student grade and mark lookup transactions',
            priority: 'P0',
            critical: true,
            slaMs: 80,
            batchable: false,
            maxBatchSize: 1,
            preferredStrategy: 'stream',
            canDefer: false,
            canShed: false,
            retryable: true,
            idempotencyRequired: true,
            processingCost: 0.6,
          ),
          EventPolicy(
            type: 'student.auth.session',
            displayName: 'Student Authentication',
            description: 'Roll number validation and session creation',
            priority: 'P0',
            critical: true,
            slaMs: 120,
            batchable: false,
            maxBatchSize: 1,
            preferredStrategy: 'stream',
            canDefer: false,
            canShed: false,
            retryable: true,
            idempotencyRequired: true,
            processingCost: 0.7,
          ),
          EventPolicy(
            type: 'payment.fee.verification',
            displayName: 'Transcript Fee Verification',
            description: 'Fee processing for official scorecard certificates',
            priority: 'P1',
            critical: false,
            slaMs: 2000,
            batchable: true,
            maxBatchSize: 80,
            preferredStrategy: 'batch',
            canDefer: false,
            canShed: false,
            retryable: true,
            idempotencyRequired: true,
            processingCost: 0.6,
          ),
          EventPolicy(
            type: 'sms.email.notification',
            displayName: 'SMS/Email Scorecard Dispatch',
            description: 'Non-blocking email and SMS dispatch alerts',
            priority: 'P2',
            critical: false,
            slaMs: 12000,
            batchable: true,
            maxBatchSize: 300,
            preferredStrategy: 'defer',
            canDefer: true,
            canShed: false,
            retryable: false,
            idempotencyRequired: false,
            processingCost: 0.4,
          ),
          EventPolicy(
            type: 'access.audit.clickstream',
            displayName: 'Web Clickstream & CDN Logs',
            description: 'Portal traffic telemetry and edge log analytics',
            priority: 'P3',
            critical: false,
            slaMs: 30000,
            batchable: true,
            maxBatchSize: 500,
            preferredStrategy: 'shed',
            canDefer: true,
            canShed: true,
            sheddingThreshold: 0.70,
            retryable: false,
            idempotencyRequired: false,
            processingCost: 0.2,
          ),
        ],
        priorityTiers: [
          PriorityTier(code: 'P0', name: 'Critical Scorecard Query', description: 'Zero-drop live grade responses.', targetSlaMs: 80),
          PriorityTier(code: 'P1', name: 'High Fee Verification', description: 'Batched payments under load.', targetSlaMs: 2000),
          PriorityTier(code: 'P2', name: 'Normal Email/SMS Alerts', description: 'Spillover queue dispatch.', targetSlaMs: 12000),
          PriorityTier(code: 'P3', name: 'Low Audit Telemetry', description: 'Sampled during traffic peak.', targetSlaMs: 30000, allowShedding: true),
        ],
      );
}
