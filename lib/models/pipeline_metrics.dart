class PipelineMetrics {
  final int eventRatePerMin;
  final int throughputPerSec;
  final double systemLoadPercentage;
  final double queuePressurePercentage;
  final double p0LatencyMs;
  final double p1LatencyMs;
  final double p2LatencyMs;
  final double p3LatencyMs;
  final int criticalEventsLost;
  final int totalDeferredCount;
  final int totalShedCount;
  final double workerUtilization;
  final DateTime timestamp;

  const PipelineMetrics({
    required this.eventRatePerMin,
    required this.throughputPerSec,
    required this.systemLoadPercentage,
    required this.queuePressurePercentage,
    required this.p0LatencyMs,
    required this.p1LatencyMs,
    required this.p2LatencyMs,
    required this.p3LatencyMs,
    required this.criticalEventsLost,
    required this.totalDeferredCount,
    required this.totalShedCount,
    required this.workerUtilization,
    required this.timestamp,
  });

  factory PipelineMetrics.initial() {
    return PipelineMetrics(
      eventRatePerMin: 1000,
      throughputPerSec: 320,
      systemLoadPercentage: 35.0,
      queuePressurePercentage: 12.0,
      p0LatencyMs: 48.0,
      p1LatencyMs: 65.0,
      p2LatencyMs: 120.0,
      p3LatencyMs: 180.0,
      criticalEventsLost: 0,
      totalDeferredCount: 0,
      totalShedCount: 0,
      workerUtilization: 42.0,
      timestamp: DateTime.now(),
    );
  }

  PipelineMetrics copyWith({
    int? eventRatePerMin,
    int? throughputPerSec,
    double? systemLoadPercentage,
    double? queuePressurePercentage,
    double? p0LatencyMs,
    double? p1LatencyMs,
    double? p2LatencyMs,
    double? p3LatencyMs,
    int? criticalEventsLost,
    int? totalDeferredCount,
    int? totalShedCount,
    double? workerUtilization,
    DateTime? timestamp,
  }) {
    return PipelineMetrics(
      eventRatePerMin: eventRatePerMin ?? this.eventRatePerMin,
      throughputPerSec: throughputPerSec ?? this.throughputPerSec,
      systemLoadPercentage: systemLoadPercentage ?? this.systemLoadPercentage,
      queuePressurePercentage: queuePressurePercentage ?? this.queuePressurePercentage,
      p0LatencyMs: p0LatencyMs ?? this.p0LatencyMs,
      p1LatencyMs: p1LatencyMs ?? this.p1LatencyMs,
      p2LatencyMs: p2LatencyMs ?? this.p2LatencyMs,
      p3LatencyMs: p3LatencyMs ?? this.p3LatencyMs,
      criticalEventsLost: criticalEventsLost ?? this.criticalEventsLost,
      totalDeferredCount: totalDeferredCount ?? this.totalDeferredCount,
      totalShedCount: totalShedCount ?? this.totalShedCount,
      workerUtilization: workerUtilization ?? this.workerUtilization,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
