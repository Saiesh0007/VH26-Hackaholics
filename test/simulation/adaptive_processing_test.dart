import 'package:flutter_test/flutter_test.dart';
import 'package:pulseflow/models/event.dart';
import 'package:pulseflow/simulation/adaptive_processing.dart';

void main() {
  test('worker failure retries only the failed event and commits once', () {
    final result = const ReliabilityScenario().run();

    expect(result.failedEvents, 1);
    expect(result.retryCount, 1);
    expect(result.committedSideEffects, result.inputEvents);
    expect(result.duplicateCount, 1);
  });

  test('weighted decision changes strategy as queue pressure changes', () {
    const function = ProcessingDecisionFunction();
    final calm = function.score(const ProcessingInputs(
      priority: 0.2,
      queueSize: 0.05,
      latency: 0.05,
      workerLoad: 0.2,
      dataSize: 0.2,
      processingCost: 0.2,
    ));
    final surge = function.score(const ProcessingInputs(
      priority: 0.2,
      queueSize: 0.95,
      latency: 0.9,
      workerLoad: 0.95,
      dataSize: 0.8,
      processingCost: 0.8,
    ));

    expect(calm.strategy, ProcessingStrategy.stream);
    expect(surge.strategy, ProcessingStrategy.batch);
    expect(surge.score, greaterThan(calm.score));
  });

  test('adaptive scaling costs less than naive always scale-up', () {
    final result = const ReliabilityScenario().run(queueSize: 80);

    expect(result.peakWorkerCount, greaterThan(result.workerCount));
    expect(result.adaptiveCost, lessThan(result.naiveScaleUpCost));
  });
}
