import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds - Near black & dark elevated surfaces
  static const Color background = Color(0xFF090D16);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceElevated = Color(0xFF1F293D);
  static const Color cardBorder = Color(0xFF2B384E);
  static const Color divider = Color(0xFF1E293B);

  // Semantic Status Colors
  static const Color healthy = Color(0xFF10B981); // Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color critical = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF06B6D4); // Cyan / Blue
  static const Color agent = Color(0xFF8B5CF6); // FlowMind Purple
  static const Color agentGlow = Color(0xFFA78BFA);

  // Priority Colors
  static const Color p0Critical = Color(0xFFEF4444); // Payment/Order Red
  static const Color p1High = Color(0xFFF59E0B); // Inventory Amber
  static const Color p2Normal = Color(0xFF3B82F6); // Activity Blue
  static const Color p3Low = Color(0xFF6B7280); // Log Gray

  // Text Colors
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Accent Gradients
  static const LinearGradient pulseGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient agentGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient criticalGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
