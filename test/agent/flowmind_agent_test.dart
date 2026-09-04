import 'package:flutter_test/flutter_test.dart';
import 'package:pulseflow/agent/flowmind_agent.dart';
import 'package:pulseflow/simulation/pipeline_runtime.dart';
import 'package:pulseflow/models/agent_state.dart';

void main() {
  group('FlowMindAgent Control Loop Tests', () {
    late FlowMindAgent agent;
    late PipelineRuntime runtime;

    setUp(() {
      agent = FlowMindAgent();
      runtime = PipelineRuntime();
    });

    test('Agent initializes in STABLE state', () {
      expect(agent.currentState, equals(FlowMindState.stable));
    });

    test('Agent transitions to WARNING and proposes surge policy during 20x spike', () {
      runtime.setTrafficRate(20000);
      final metrics = runtime.tickSimulation();

      agent.runControlLoop(runtime, metrics);

      expect(agent.decisionsHistory.isNotEmpty, isTrue);
      final decision = agent.decisionsHistory.first;
      expect(decision.safetyValidated, isTrue);
    });
  });
}
