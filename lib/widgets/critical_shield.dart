import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';

class CriticalShield extends StatelessWidget {
  final bool isExtremeSpike;
  final int criticalLost;
  final int deferredCount;
  final int shedCount;

  const CriticalShield({
    super.key,
    required this.isExtremeSpike,
    required this.criticalLost,
    this.deferredCount = 0,
    this.shedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExtremeSpike
              ? AppColors.healthy.withOpacity(0.8)
              : AppColors.cardBorder,
          width: isExtremeSpike ? 1.5 : 1.0,
        ),
        boxShadow: isExtremeSpike
            ? [
                BoxShadow(
                  color: AppColors.healthy.withOpacity(0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shield,
                    color: AppColors.healthy,
                    size: 24,
                  )
                      .animate(
                        onPlay: (controller) => controller.repeat(reverse: true),
                      )
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.12, 1.12),
                        duration: 1200.ms,
                      ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CRITICAL EVENT SHIELD',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Immutable Safety Guard Rules Active',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.healthy.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.healthy.withOpacity(0.5)),
                ),
                child: const Text(
                  '🛡 100% PROTECTED',
                  style: TextStyle(
                    color: AppColors.healthy,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildShieldItem(
                  label: 'P0 LOST',
                  value: '$criticalLost',
                  color: criticalLost > 0 ? AppColors.critical : AppColors.healthy,
                ),
              ),
              Expanded(
                child: _buildShieldItem(
                  label: 'P2 DEFERRED',
                  value: '$deferredCount',
                  color: deferredCount > 0 ? AppColors.warning : AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: _buildShieldItem(
                  label: 'P3 SHED',
                  value: '$shedCount',
                  color: shedCount > 0 ? AppColors.info : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShieldItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
