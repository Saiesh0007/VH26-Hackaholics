class SimulationConfig {
  final int baselineTrafficRate;
  final int spikeMultiplier;
  final int workerCount;
  final int maxQueueCapacity;
  final double baseProcessingCostMs;

  const SimulationConfig({
    required this.baselineTrafficRate,
    required this.spikeMultiplier,
    required this.workerCount,
    required this.maxQueueCapacity,
    required this.baseProcessingCostMs,
  });

  factory SimulationConfig.defaultConfig() {
    return const SimulationConfig(
      baselineTrafficRate: 1000,
      spikeMultiplier: 20,
      workerCount: 16,
      maxQueueCapacity: 20000,
      baseProcessingCostMs: 15.0,
    );
  }
}
