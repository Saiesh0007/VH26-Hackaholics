enum FlowMindState {
  observing,
  analyzing,
  reasoning,
  proposing,
  validating,
  executing,
  verifying,
  stable,
  warning,
  recovering,
}

extension FlowMindStateX on FlowMindState {
  String get label {
    switch (this) {
      case FlowMindState.observing:
        return 'OBSERVING';
      case FlowMindState.analyzing:
        return 'ANALYZING';
      case FlowMindState.reasoning:
        return 'REASONING';
      case FlowMindState.proposing:
        return 'PROPOSING';
      case FlowMindState.validating:
        return 'VALIDATING';
      case FlowMindState.executing:
        return 'EXECUTING POLICY';
      case FlowMindState.verifying:
        return 'VERIFYING';
      case FlowMindState.stable:
        return 'STABLE';
      case FlowMindState.warning:
        return 'PRESSURE WARNING';
      case FlowMindState.recovering:
        return 'RECOVERING';
    }
  }

  String get shortCode {
    switch (this) {
      case FlowMindState.observing:
        return 'OBS';
      case FlowMindState.analyzing:
        return 'ANZ';
      case FlowMindState.reasoning:
        return 'RSN';
      case FlowMindState.proposing:
        return 'PRP';
      case FlowMindState.validating:
        return 'VAL';
      case FlowMindState.executing:
        return 'EXE';
      case FlowMindState.verifying:
        return 'VRF';
      case FlowMindState.stable:
        return 'STB';
      case FlowMindState.warning:
        return 'WRN';
      case FlowMindState.recovering:
        return 'RCV';
    }
  }
}

class AgentStateSummary {
  final FlowMindState state;
  final String currentObjective;
  final String currentCondition;
  final String activeActionDescription;
  final DateTime lastStateChange;

  const AgentStateSummary({
    required this.state,
    required this.currentObjective,
    required this.currentCondition,
    required this.activeActionDescription,
    required this.lastStateChange,
  });

  factory AgentStateSummary.initial() {
    return AgentStateSummary(
      state: FlowMindState.stable,
      currentObjective: 'Protect critical workloads & maintain baseline latency',
      currentCondition: 'Traffic normal (~1,000 events/min)',
      activeActionDescription: 'Streaming P0/P1; Standard processing active',
      lastStateChange: DateTime.now(),
    );
  }
}
