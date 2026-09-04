enum IncidentSeverity {
  info,
  warning,
  critical,
}

class SystemIncident {
  final String id;
  final String title;
  final String description;
  final IncidentSeverity severity;
  final DateTime timestamp;
  final String status; // 'RESOLVED', 'ACTIVE', 'MITIGATED'

  const SystemIncident({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
    required this.status,
  });
}
