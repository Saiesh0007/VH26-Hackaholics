import 'dart:math';

import '../models/event.dart';

class ProcessingInputs {
  final double priority;
  final double queueSize;
  final double latency;
  final double workerLoad;
  final double dataSize;
  final double processingCost;

  const ProcessingInputs({
    required this.priority,
    required this.queueSize,
    required this.latency,
    required this.workerLoad,
    required this.dataSize,
    required this.processingCost,
  });
}

class ProcessingScore {
  final ProcessingStrategy strategy;
  final double score;
  final String explanation;

  const ProcessingScore({
    required this.strategy,
    required this.score,
    required this.explanation,
  });
}

/// Weighted decision function used by the adaptive router.
class ProcessingDecisionFunction {
  const ProcessingDecisionFunction();

  ProcessingScore score(ProcessingInputs input) {
    final urgency = (input.priority * 0.30) +
        (input.queueSize * 0.20) +
        (input.latency * 0.20) +
        (input.workerLoad * 0.15) +
        (input.dataSize * 0.05) +
        (input.processingCost * 0.10);

    if (input.priority >= 0.85) {
      return ProcessingScore(
        strategy: ProcessingStrategy.stream,
        score: urgency,
        explanation:
            'Critical priority weight keeps the event on the streaming lane.',
      );
    }
    if (urgency >= 0.62) {
      return ProcessingScore(
        strategy: ProcessingStrategy.batch,
        score: urgency,
        explanation:
            'Queue, latency, and worker-load weights favor micro-batching.',
      );
    }
    if (urgency >= 0.42) {
      return ProcessingScore(
        strategy: ProcessingStrategy.defer,
        score: urgency,
        explanation:
            'Moderate pressure favors deferral while protecting capacity.',
      );
    }
    return ProcessingScore(
      strategy: ProcessingStrategy.stream,
      score: urgency,
      explanation: 'Low weighted pressure favors immediate streaming.',
    );
  }
}

class ReliabilityScenarioResult {
  final int inputEvents;
  final int committedSideEffects;
  final int retryCount;
  final int duplicateCount;
  final int failedEvents;
  final int workerCount;
  final int peakWorkerCount;
  final double adaptiveCost;
  final double naiveScaleUpCost;
  final ProcessingScore decision;

  const ReliabilityScenarioResult({
    required this.inputEvents,
    required this.committedSideEffects,
    required this.retryCount,
    required this.duplicateCount,
    required this.failedEvents,
    required this.workerCount,
    required this.peakWorkerCount,
    required this.adaptiveCost,
    required this.naiveScaleUpCost,
    required this.decision,
  });

  double get costSavingsPercent =>
      naiveScaleUpCost == 0 ? 0 : (1 - adaptiveCost / naiveScaleUpCost) * 100;
}

/// Deterministic demo of worker failure, idempotency, scaling, and cost.
class ReliabilityScenario {
  final ProcessingDecisionFunction decisionFunction;

  const ReliabilityScenario({
    this.decisionFunction = const ProcessingDecisionFunction(),
  });

  ReliabilityScenarioResult run({
    int queueSize = 240,
    double latencyMs = 180,
    double workerLoad = 0.88,
    double dataSize = 0.55,
    double processingCost = 0.60,
  }) {
    final decision = decisionFunction.score(ProcessingInputs(
      priority: 0.62,
      queueSize: (queueSize / 500).clamp(0.0, 1.0),
      latency: (latencyMs / 500).clamp(0.0, 1.0),
      workerLoad: workerLoad,
      dataSize: dataSize,
      processingCost: processingCost,
    ));

    final workerCount = max(2, min(12, 2 + (queueSize / 80).ceil()));
    final peakWorkerCount =
        max(workerCount, min(16, 2 + (queueSize / 35).ceil()));
    const inputEvents = 12;

    final committedIds = <String>{};
    var retryCount = 0;
    var duplicateCount = 0;
    var failedEvents = 0;
    for (var index = 0; index < inputEvents; index++) {
      final eventId = 'checkout-${index + 1}';
      if (index == 4) {
        failedEvents++;
        retryCount++;
      }
      if (!committedIds.add(eventId)) {
        duplicateCount++;
      }
    }
    if (!committedIds.add('checkout-5')) duplicateCount++;

    final adaptiveCost =
        workerCount * 0.42 + (peakWorkerCount - workerCount) * 0.18;
    const naiveScaleUpCost = 16 * 0.72;
    return ReliabilityScenarioResult(
      inputEvents: inputEvents,
      committedSideEffects: committedIds.length,
      retryCount: retryCount,
      duplicateCount: duplicateCount,
      failedEvents: failedEvents,
      workerCount: workerCount,
      peakWorkerCount: peakWorkerCount,
      adaptiveCost: adaptiveCost,
      naiveScaleUpCost: naiveScaleUpCost,
      decision: decision,
    );
  }
}
