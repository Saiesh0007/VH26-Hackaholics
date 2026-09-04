import 'package:flutter/material.dart';
import '../models/processing_decision.dart';
import '../core/theme/app_colors.dart';
import 'priority_badge.dart';

class DecisionCard extends StatelessWidget {
  final ProcessingDecision decision;

  const DecisionCard({
    super.key,
    required this.decision,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: decision.safetyValidated
              ? AppColors.cardBorder
              : AppColors.critical.withOpacity(0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '🤖 FLOWMIND',
                    style: TextStyle(
                      color: AppColors.agent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PriorityBadge(priority: decision.targetPriority),
                ],
              ),
              Text(
                decision.timestamp.toIso8601String().substring(11, 19),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACTION',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    decision.action.name.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.info,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BATCH SIZE',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    decision.batchSize.toString(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'REASON',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            decision.reason,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: decision.safetyValidated
                  ? AppColors.healthy.withOpacity(0.12)
                  : AppColors.critical.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  decision.safetyValidated
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  size: 12,
                  color: decision.safetyValidated
                      ? AppColors.healthy
                      : AppColors.critical,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    decision.safetyExplanation,
                    style: TextStyle(
                      color: decision.safetyValidated
                          ? AppColors.healthy
                          : AppColors.critical,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
