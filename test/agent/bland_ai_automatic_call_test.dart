import 'package:flutter_test/flutter_test.dart';
import 'package:pulseflow/services/bland_ai_service.dart';
import 'package:pulseflow/simulation/simulation_engine.dart';

void main() {
  group('Automatic Bland AI Emergency Calling Tests', () {
    test('BlandAiService operates as a unified singleton with broadcast stream', () {
      final s1 = BlandAiService();
      final s2 = BlandAiService();
      expect(identical(s1, s2), isTrue);
    });

    test('Triggering an extreme edge case (100k e/min) automatically emits an emergency call', () async {
      final blandService = BlandAiService();
      final engine = SimulationEngine();

      BlandAiCallRecord? capturedCall;
      final sub = blandService.onEmergencyCall.listen((record) {
        capturedCall = record;
      });

      // Trigger 100k extreme stress edge case
      engine.setTrafficRate(100000);

      // Allow async delay to fire
      await Future.delayed(const Duration(milliseconds: 1500));

      expect(capturedCall, isNotNull);
      expect(capturedCall!.reason, contains('exceeding autonomous mitigation thresholds'));

      await sub.cancel();
      engine.dispose();
    });
  });
}
