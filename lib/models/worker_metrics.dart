class WorkerNodeMetrics {
  final String id;
  final String assignedQueue;
  final double cpuUtilizationPercentage;
  final double memoryUsageMb;
  final int activeTasks;
  final bool isHealthy;

  const WorkerNodeMetrics({
    required this.id,
    required this.assignedQueue,
    required this.cpuUtilizationPercentage,
    required this.memoryUsageMb,
    required this.activeTasks,
    required this.isHealthy,
  });
}
