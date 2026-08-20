import 'package:flutter/material.dart';

class AppColors {
  // Brand Palette - Premium Crimson / Ruby Red Theme
  static const Color brandPrimary = Color(0xFFE11D48); // Vibrant Royal Crimson / Ruby Red
  static const Color brandPrimaryHover = Color(0xFFBE123C);
  static const Color brandPrimaryLight = Color(0xFFFFE4E6); // Soft Rose Tint
  static const Color brandPrimaryGhost = Color(0xFFFFF1F2);
  
  static const Color brandSecondary = Color(0xFF0F172A); // Deep Navy Slate
  static const Color brandSecondaryLight = Color(0xFF1E293B);
  
  static const Color brandAccent = Color(0xFF059669); // Emerald Green for success
  static const Color brandAccentLight = Color(0xFFECFDF5); // Soft Mint Pastel

  // Clean Crisp Light Surfaces
  static const Color background = Color(0xFFF8FAFC); // Clean Canvas White
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0); // Subtle Border
  static const Color borderSubtle = Color(0xFFF1F5F9);
  static const Color borderFocus = Color(0xFFE11D48);
  
  // Typography
  static const Color textPrimary = Color(0xFF0F172A); // Deep Navy Slate
  static const Color textSecondary = Color(0xFF64748B); // Muted Slate
  static const Color textMuted = Color(0xFF94A3B8); // Light Slate
  static const Color textDisabled = Color(0xFFCBD5E1);

  // Status & Semantic Feedback (Crisp Pastels)
  static const Color statusPendingBg = Color(0xFFFEF3C7); // Warm Amber
  static const Color statusPendingFg = Color(0xFFB45309);
  static const Color statusAssignedBg = Color(0xFFEEF2FF); // Indigo
  static const Color statusAssignedFg = Color(0xFF4338CA);
  static const Color statusPickedUpBg = Color(0xFFE0F2FE); // Sky Blue
  static const Color statusPickedUpFg = Color(0xFF0369A1);
  static const Color statusOnTheWayBg = Color(0xFFFFE4E6); // Rose Tint
  static const Color statusOnTheWayFg = Color(0xFFBE123C);
  static const Color statusDeliveredBg = Color(0xFFD1FAE5); // Emerald Green
  static const Color statusDeliveredFg = Color(0xFF047857);
  static const Color statusCancelledBg = Color(0xFFFEE2E2); // Crimson Red
  static const Color statusCancelledFg = Color(0xFFB91C1C);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Backward Compatible Aliases
  static const Color primary = brandPrimary;
  static const Color primaryDark = brandSecondary;
  static const Color accent = brandAccent;
  static const Color warningBg = statusPendingBg;
  static const Color errorBg = statusCancelledBg;
  static const Color successBg = statusDeliveredBg;

  // Map & Live Tracking Palette
  static const Color mapBg = Color(0xFFE2E8F0);
  static const Color mapRiderMarker = Color(0xFFE11D48);
  static const Color mapStoreMarker = Color(0xFF059669);
  static const Color mapDestinationMarker = Color(0xFFDC2626);
  static const Color mapRoutePolyline = Color(0xFFE11D48);

  // Premium Crimson / Ruby Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroLightGradient = LinearGradient(
    colors: [Color(0xFFFFF1F2), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardHeaderGradient = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Shadows
  static const List<BoxShadow> premiumShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x05000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x33E11D48),
      blurRadius: 12,
      offset: Offset(0, 5),
    ),
  ];
}
