import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class BackpressureGauge extends StatelessWidget {
  final double queuePressurePercentage;

  const BackpressureGauge({
    super.key,
    required this.queuePressurePercentage,
  });

  @override
  Widget build(BuildContext context) {
    final isHigh = queuePressurePercentage > 50;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHigh ? AppColors.warning.withOpacity(0.8) : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BACKPRESSURE STATUS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isHigh ? AppColors.warning : AppColors.healthy).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isHigh ? 'BACKPRESSURE ACTIVE' : 'OPTIMAL INTAKE',
                  style: TextStyle(
                    color: isHigh ? AppColors.warning : AppColors.healthy,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Queue Depth', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (queuePressurePercentage / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(isHigh ? AppColors.warning : AppColors.healthy),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '${queuePressurePercentage.toInt()}%',
                style: TextStyle(
                  color: isHigh ? AppColors.warning : AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
