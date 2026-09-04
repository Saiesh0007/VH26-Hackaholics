import 'package:flutter/material.dart';
import '../models/agent_state.dart';
import '../core/theme/app_colors.dart';

class AgentStatusIndicator extends StatelessWidget {
  final FlowMindState state;

  const AgentStatusIndicator({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (state) {
      case FlowMindState.stable:
        color = AppColors.healthy;
        break;
      case FlowMindState.observing:
      case FlowMindState.analyzing:
      case FlowMindState.reasoning:
      case FlowMindState.proposing:
      case FlowMindState.validating:
      case FlowMindState.executing:
      case FlowMindState.verifying:
        color = AppColors.agent;
        break;
      case FlowMindState.warning:
        color = AppColors.warning;
        break;
      case FlowMindState.recovering:
        color = AppColors.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.6),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '🤖 FLOWMIND ● ${state.label}',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
