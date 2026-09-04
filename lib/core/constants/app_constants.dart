class AppConstants {
  static const String appName = 'PULSEFLOW';
  static const String appTagline = 'Process what matters. Defer what can wait.';

  // Traffic Constants
  static const int normalTrafficRate = 1000; // events / min
  static const int spikeTrafficRate = 20000; // events / min (20x)
  static const int maxQueueCapacity = 20000;

  // Max bounded memory for live events to maintain 60 FPS performance
  static const int maxEventHistorySize = 100;
  static const int maxMetricsHistorySize = 60;
  static const int maxAgentLogSize = 50;

  // Safety Rules
  static const int maxBatchSizeLimit = 1000;
  static const int maxDeferWindowSecondsLimit = 60;
  static const double maxSamplingRateLimit = 0.90; // 90% shed max
}
