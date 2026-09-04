import 'package:flutter_test/flutter_test.dart';
import 'package:pulseflow/simulation/simulation_engine.dart';

void main() {
  group('SimulationEngine Tests', () {
    late SimulationEngine engine;

    setUp(() {
      engine = SimulationEngine();
    });

    tearDown(() {
      engine.dispose();
    });

    test('Simulation engine triggers 20x spike and records incident', () {
      engine.startSimulation();
      engine.trigger20xSpike();

      expect(engine.runtime.trafficRate, equals(20000));
      expect(engine.incidents.first.title, contains('20× TRAFFIC SPIKE'));
    });

    test('Simulation engine recovers to normal baseline', () {
      engine.startSimulation();
      engine.trigger20xSpike();
      engine.recoverToNormal();

      expect(engine.runtime.trafficRate, equals(1000));
      expect(engine.incidents.first.title, contains('RECOVERY'));
    });
  });
}
