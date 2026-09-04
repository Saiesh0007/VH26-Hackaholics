import '../models/pipeline_metrics.dart';

class CopilotAdvice {
  final String title;
  final String message;
  final String icon;
  final String type; // 'warning', 'info', 'success'

  const CopilotAdvice({
    required this.title,
    required this.message,
    required this.icon,
    required this.type,
  });
}

class CopilotService {
  List<CopilotAdvice> generateAdvice(PipelineMetrics metrics) {
    final List<CopilotAdvice> insights = [];

    if (metrics.eventRatePerMin >= 15000) {
      insights.add(const CopilotAdvice(
        title: '20× Traffic Spike Active',
        message: 'FlowMind has engaged extreme surge protection. Non-critical logs are sampled at 20%.',
        icon: '🔥',
        type: 'warning',
      ));
    }

    if (metrics.p0LatencyMs < 60) {
      insights.add(const CopilotAdvice(
        title: 'P0 Latency Safe',
        message: 'Payment and Order end-to-end latency remains within green zone (< 60ms).',
        icon: '🛡',
        type: 'success',
      ));
    }

    if (metrics.queuePressurePercentage > 40) {
      insights.add(const CopilotAdvice(
        title: 'P2 Activity Queue Pressure',
        message: 'FlowMind recommends intentional deferral window to clear worker backlogs.',
        icon: '⚡',
        type: 'info',
      ));
    }

    return insights;
  }
}
