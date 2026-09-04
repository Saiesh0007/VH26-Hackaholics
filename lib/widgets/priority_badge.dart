import 'package:flutter/material.dart';
import '../models/event.dart';
import '../core/theme/app_colors.dart';

class PriorityBadge extends StatelessWidget {
  final WorkloadPriority priority;

  const PriorityBadge({
    super.key,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority) {
      case WorkloadPriority.p0Payment:
      case WorkloadPriority.p0Order:
        color = AppColors.p0Critical;
        break;
      case WorkloadPriority.p1Inventory:
        color = AppColors.p1High;
        break;
      case WorkloadPriority.p2Activity:
        color = AppColors.p2Normal;
        break;
      case WorkloadPriority.p3Log:
        color = AppColors.p3Low;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        '${priority.code} ${priority.displayName}',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
