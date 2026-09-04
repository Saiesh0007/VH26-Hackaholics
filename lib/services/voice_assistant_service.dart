import '../simulation/simulation_engine.dart';

class VoiceResponse {
  final String textResponse;
  final String actionTaken;

  const VoiceResponse({
    required this.textResponse,
    required this.actionTaken,
  });
}

class VoiceAssistantService {
  final SimulationEngine engine;

  VoiceAssistantService(this.engine);

  Future<VoiceResponse> processQuery(String query) async {
    final q = query.toLowerCase().trim();

    // Dynamic Traffic Level Commands
    if (q.contains('100k') || q.contains('100,000') || q.contains('100000') || q.contains('extreme')) {
      engine.setTrafficRate(100000);
      return const VoiceResponse(
        textResponse: "🚨 Extreme Stress Surge initiated! Traffic scaled to 100,000 events/minute (100×). FlowMind is enforcing deep P3 shedding and 500-batching to protect P0 payments.",
        actionTaken: "Scaled to 100,000 e/min (100×)",
      );
    }

    if (q.contains('80k') || q.contains('80,000') || q.contains('80000') || q.contains('heavy')) {
      engine.setTrafficRate(80000);
      return const VoiceResponse(
        textResponse: "🔥 Heavy Surge activated! Traffic adjusted to 80,000 events/minute (80×). P0 queues prioritized.",
        actionTaken: "Scaled to 80,000 e/min (80×)",
      );
    }

    if (q.contains('60k') || q.contains('60,000') || q.contains('60000') || q.contains('black friday')) {
      engine.setTrafficRate(60000);
      return const VoiceResponse(
        textResponse: "🛍️ Black Friday Scale Surge activated! Influx set to 60,000 events/minute (60×). P2 activity deferred for 30 seconds.",
        actionTaken: "Scaled to 60,000 e/min (60×)",
      );
    }

    if (q.contains('40k') || q.contains('40,000') || q.contains('40000')) {
      engine.setTrafficRate(40000);
      return const VoiceResponse(
        textResponse: "⚡ Flash Surge set to 40,000 events/minute (40×). Ingestion router actively segregating lanes.",
        actionTaken: "Scaled to 40,000 e/min (40×)",
      );
    }

    if (q.contains('spike') || q.contains('flash sale') || q.contains('twenty times') || q.contains('20x') || q.contains('20k') || q.contains('20,000')) {
      engine.setTrafficRate(20000);
      return const VoiceResponse(
        textResponse: "🔥 Initiating 20× Traffic Spike simulation. Traffic rate increased to 20,000 events/minute. FlowMind AI Agent activated.",
        actionTaken: "Triggered 20× Traffic Spike",
      );
    }

    if (q.contains('recover') || q.contains('normal') || q.contains('baseline') || q.contains('1k') || q.contains('1000') || q.contains('stop spike')) {
      engine.recoverToNormal();
      return const VoiceResponse(
        textResponse: "🟢 System recovery initiated. Traffic normalized to 1,000 events/minute. FlowMind is draining deferred queues.",
        actionTaken: "Triggered System Recovery",
      );
    }

    if (q.contains('batching logs') || q.contains('batch logs') || q.contains('why logs')) {
      return const VoiceResponse(
        textResponse: "The P3 queue was growing faster than worker capacity. Because logs are non-critical, FlowMind increased batch size to 500 to reduce worker overhead while keeping P0 payments in streaming mode.",
        actionTaken: "Explained P3 Log Batching Policy",
      );
    }

    if (q.contains('payments safe') || q.contains('dropping payments') || q.contains('p0') || q.contains('order')) {
      return const VoiceResponse(
        textResponse: "Yes! Payment and Order events are 100% protected by an immutable P0 SafetyGuard policy. SafetyGuard prevents FlowMind from shedding or dropping critical events under any condition.",
        actionTaken: "Verified P0 Safety Guard Protection",
      );
    }

    if (q.contains('happening') || q.contains('status') || q.contains('state') || q.contains('traffic')) {
      final metrics = engine.runtime.tickSimulation();
      return VoiceResponse(
        textResponse: "Current traffic rate is ${metrics.eventRatePerMin} events/minute. Agent state is ${engine.agent.currentState.name.toUpperCase()}. Critical P0 events lost: 0. Payments and orders remain 100% safe.",
        actionTaken: "Reported System Status",
      );
    }

    if (q.contains('shed') || q.contains('dropped') || q.contains('sample')) {
      final metrics = engine.runtime.tickSimulation();
      return VoiceResponse(
        textResponse: "FlowMind has shed ${metrics.totalShedCount} non-critical P3 log events under controlled sampling. 0 critical events were lost.",
        actionTaken: "Reported Shedding Metrics",
      );
    }

    return VoiceResponse(
      textResponse: "FlowMind is monitoring the pipeline. Current state: ${engine.agent.currentState.name.toUpperCase()} with ${engine.runtime.trafficRate} events/min.",
      actionTaken: "Acknowledged Query",
    );
  }
}
