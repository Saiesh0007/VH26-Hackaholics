import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pipeline_provider.dart';

class DemoStep {
  final int stepNumber;
  final String title;
  final String narration;
  final String actionLabel;

  const DemoStep({
    required this.stepNumber,
    required this.title,
    required this.narration,
    required this.actionLabel,
  });
}

class DemoState {
  final bool isDemoActive;
  final int currentStepIndex;
  final List<DemoStep> steps;

  const DemoState({
    required this.isDemoActive,
    required this.currentStepIndex,
    required this.steps,
  });

  DemoStep get currentStep => steps[currentStepIndex];

  DemoState copyWith({
    bool? isDemoActive,
    int? currentStepIndex,
    List<DemoStep>? steps,
  }) {
    return DemoState(
      isDemoActive: isDemoActive ?? this.isDemoActive,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      steps: steps ?? this.steps,
    );
  }
}

class DemoNotifier extends StateNotifier<DemoState> {
  final Ref ref;

  DemoNotifier(this.ref)
      : super(const DemoState(
          isDemoActive: false,
          currentStepIndex: 0,
          steps: [
            DemoStep(
              stepNumber: 1,
              title: 'STEP 1: NORMAL TRAFFIC',
              narration: 'Baseline traffic running at ~1,000 events/min. All workloads (P0 to P3) streaming smoothly.',
              actionLabel: 'NEXT: TRIGGER SPIKE',
            ),
            DemoStep(
              stepNumber: 2,
              title: 'STEP 2: 20× TRAFFIC SPIKE',
              narration: 'Flash sale simulated! Ingestion rate spikes 20× to 20,000 events/min.',
              actionLabel: 'NEXT: FLOWMIND ACTIVATION',
            ),
            DemoStep(
              stepNumber: 3,
              title: 'STEP 3: FLOWMIND OBSERVES & ANALYZES',
              narration: 'FlowMind detects CPU worker utilization at 91% and P3 log queue saturation.',
              actionLabel: 'NEXT: ADAPTIVE BATCHING',
            ),
            DemoStep(
              stepNumber: 4,
              title: 'STEP 4: ADAPTIVE MICRO-BATCHING',
              narration: 'FlowMind changes P2 Activity & P3 Logs to Micro-Batching (250 & 500 size). Worker overhead drops.',
              actionLabel: 'NEXT: SAFETY GUARD VALIDATION',
            ),
            DemoStep(
              stepNumber: 5,
              title: 'STEP 5: SAFETY GUARD ENFORCEMENT',
              narration: 'SafetyGuard verifies: P0 Payments & Orders NEVER shed or batched. 100% latency SLA protected!',
              actionLabel: 'NEXT: LOAD SHEDDING',
            ),
            DemoStep(
              stepNumber: 6,
              title: 'STEP 6: CONTROLLED LOAD SHEDDING',
              narration: 'Extreme pressure continues. FlowMind defers P2 Activity and samples P3 Logs (80% shed). P0 payments unharmed.',
              actionLabel: 'NEXT: VERIFICATION',
            ),
            DemoStep(
              stepNumber: 7,
              title: 'STEP 7: POLICY VERIFICATION',
              narration: 'FlowMind verifies P0 latency remains at 48ms. Policy validated and kept stable.',
              actionLabel: 'NEXT: RECOVERY',
            ),
            DemoStep(
              stepNumber: 8,
              title: 'STEP 8: SYSTEM RECOVERY',
              narration: 'Traffic normalizes to 1,000/min. Queues drain, deferred workloads process, streaming restored.',
              actionLabel: 'NEXT: BENCHMARK',
            ),
            DemoStep(
              stepNumber: 9,
              title: 'STEP 9: NAIVE VS ADAPTQ BENCHMARK',
              narration: 'Compare Naive processing (100% failure during spike) vs AdaptQ (0 P0 events lost).',
              actionLabel: 'FINISH DEMO',
            ),
          ],
        ));

  void startDemo() {
    state = state.copyWith(isDemoActive: true, currentStepIndex: 0);
  }

  void stopDemo() {
    state = state.copyWith(isDemoActive: false);
  }

  void nextStep() {
    if (state.currentStepIndex < state.steps.length - 1) {
      final newIndex = state.currentStepIndex + 1;
      state = state.copyWith(currentStepIndex: newIndex);
      _executeStepAction(newIndex);
    } else {
      stopDemo();
    }
  }

  void previousStep() {
    if (state.currentStepIndex > 0) {
      final newIndex = state.currentStepIndex - 1;
      state = state.copyWith(currentStepIndex: newIndex);
      _executeStepAction(newIndex);
    }
  }

  void _executeStepAction(int stepIndex) {
    final engine = ref.read(simulationEngineProvider);
    if (stepIndex == 1) {
      engine.trigger20xSpike();
    } else if (stepIndex == 7) {
      engine.recoverToNormal();
    }
  }
}

final demoProvider = StateNotifierProvider<DemoNotifier, DemoState>((ref) {
  return DemoNotifier(ref);
});
