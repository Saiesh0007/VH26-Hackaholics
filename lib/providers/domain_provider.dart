import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/domain_policy.dart';
import '../services/ai_domain_service.dart';
import 'pipeline_provider.dart';
import 'settings_provider.dart';

final aiDomainServiceProvider = Provider<AiDomainService>((ref) {
  final settings = ref.watch(settingsProvider);
  return AiDomainService(baseUrl: settings.backendUrl);
});

class DomainState {
  final DomainPolicy activePolicy;
  final List<DomainPolicy> availablePolicies;
  final bool isGenerating;
  final String? lastError;

  const DomainState({
    required this.activePolicy,
    required this.availablePolicies,
    this.isGenerating = false,
    this.lastError,
  });

  DomainState copyWith({
    DomainPolicy? activePolicy,
    List<DomainPolicy>? availablePolicies,
    bool? isGenerating,
    String? lastError,
  }) {
    return DomainState(
      activePolicy: activePolicy ?? this.activePolicy,
      availablePolicies: availablePolicies ?? this.availablePolicies,
      isGenerating: isGenerating ?? this.isGenerating,
      lastError: lastError,
    );
  }
}

class DomainNotifier extends StateNotifier<DomainState> {
  final Ref _ref;

  DomainNotifier(this._ref)
      : super(DomainState(
          activePolicy: DomainPolicy.ecommerce(),
          availablePolicies: [
            DomainPolicy.ecommerce(),
            DomainPolicy.hospital(),
            DomainPolicy.education(),
          ],
        ));

  void switchDomain(DomainPolicy policy) {
    state = state.copyWith(activePolicy: policy);
    _ref.read(simulationEngineProvider).setDomainPolicy(policy);
  }

  void addAndActivatePolicy(DomainPolicy policy) {
    final existingIndex = state.availablePolicies
        .indexWhere((p) => p.domainName.toLowerCase() == policy.domainName.toLowerCase());

    List<DomainPolicy> updated;
    if (existingIndex >= 0) {
      updated = List<DomainPolicy>.from(state.availablePolicies);
      updated[existingIndex] = policy;
    } else {
      updated = [...state.availablePolicies, policy];
    }

    state = state.copyWith(
      activePolicy: policy,
      availablePolicies: updated,
    );
    _ref.read(simulationEngineProvider).setDomainPolicy(policy);
  }

  void setGenerating(bool val) {
    state = state.copyWith(isGenerating: val);
  }

  void setError(String? error) {
    state = state.copyWith(lastError: error);
  }
}

final domainProvider = StateNotifierProvider<DomainNotifier, DomainState>((ref) {
  return DomainNotifier(ref);
});
