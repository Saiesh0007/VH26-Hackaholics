import 'package:flutter/material.dart';

/// AdaptQ Pastel Blue & White Design System
/// A refined, harmonious palette composed of shades of pastel blues (from light frost to dark midnight slate) and crisp pure white.
class AppColors {
  // Pastel Blue Spectrum (Light to Deep) & White
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color pastelIce = Color(0xFFF0F7FF);       // Lightest frosty ice blue
  static const Color pastelPowder = Color(0xFFD6E8FF);    // Soft powder baby blue
  static const Color pastelSky = Color(0xFF93C5FD);       // Soft airy sky blue
  static const Color pastelBlue = Color(0xFF60A5FA);      // Radiant signature pastel blue
  static const Color pastelAzure = Color(0xFF38BDF8);     // Crisp vibrant pastel cyan-blue
  static const Color pastelDenim = Color(0xFF3B82F6);     // Rich medium pastel cobalt
  static const Color pastelSteel = Color(0xFF2563EB);     // Deep accent blue

  // Brand Primary & Accents (Pastel Blue)
  static const Color primary = Color(0xFF60A5FA);         // Signature Pastel Blue
  static const Color primaryLight = Color(0xFF93C5FD);    // Light pastel highlight
  static const Color primaryDark = Color(0xFF2563EB);     // Deep pastel blue
  static const Color accentBlue = Color(0xFF38BDF8);      // Electric soft cyan accent

  // Geometry & Radii
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(28));
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius cardRadiusLarge = BorderRadius.all(Radius.circular(24));

  // Ambient Shadows & Luminous Glows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x40060E20), blurRadius: 18, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> blueGlowShadow = [
    BoxShadow(color: Color(0x4060A5FA), blurRadius: 20, spreadRadius: 1),
  ];
  // Backwards compatibility alias
  static const List<BoxShadow> orangeGlowShadow = blueGlowShadow;

  // Dark Pastel Blue Surfaces (from deepest midnight to elevated slate blue)
  static const Color background = Color(0xFF091020);      // Deepest midnight pastel navy
  static const Color surface = Color(0xFF0F1B35);         // Rich dark pastel blue container
  static const Color surfaceElevated = Color(0xFF17284C); // Elevated card / button surface
  static const Color surfaceHover = Color(0xFF1E3563);    // Interactive hover state
  static const Color cardBorder = Color(0xFF233C6E);      // Translucent slate-blue border
  static const Color divider = Color(0xFF162544);         // Dark pastel navy hairline divider

  // Semantic Status Colors (Pastel Tinted)
  static const Color healthy = Color(0xFF34D399);          // Pastel emerald mint
  static const Color warning = Color(0xFFFBBF24);          // Pastel amber
  static const Color critical = Color(0xFFF87171);         // Pastel soft coral / red
  static const Color info = Color(0xFF7DD3FC);             // Pastel ice cyan
  static const Color agent = Color(0xFF818CF8);            // Pastel periwinkle blue
  static const Color agentGlow = Color(0xFFA5B4FC);        // Pastel lavender mist

  // Priority Routing Colors (Harmonized with Pastel Blue)
  static const Color p0Critical = Color(0xFFF87171);       // Pastel coral red
  static const Color p1High = Color(0xFFFBBF24);           // Pastel golden amber
  static const Color p2Normal = Color(0xFF60A5FA);         // Pastel sky azure
  static const Color p3Low = Color(0xFF94A3B8);            // Pastel slate gray

  // Text Hierarchy (White to Light Pastel Blue)
  static const Color textPrimary = Color(0xFFFFFFFF);      // Pure crisp white
  static const Color textSecondary = Color(0xFFBFDBFE);    // Frosted light pastel blue
  static const Color textMuted = Color(0xFF7EA0CF);        // Muted pastel denim

  // Gradients (Pastel Blue to Deep Blue & White)
  static const LinearGradient pulseGradient = LinearGradient(
    colors: [Color(0xFFBAE6FD), Color(0xFF60A5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient agentGradient = LinearGradient(
    colors: [Color(0xFFA5B4FC), Color(0xFF60A5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient criticalGradient = LinearGradient(
    colors: [Color(0xFFF87171), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueHeroGradient = LinearGradient(
    colors: [Color(0xFF93C5FD), Color(0xFF60A5FA), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
