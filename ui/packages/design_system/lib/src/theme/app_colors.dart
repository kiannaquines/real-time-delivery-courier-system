import 'package:flutter/material.dart';

class AppColors {
  // Brand Palette (M&S Delivery Express - Unified Modern Palette)
  static const Color brandPrimary = Color(0xFFF97316); // Vibrant Coral Amber / Orange
  static const Color brandPrimaryHover = Color(0xFFEA580C);
  static const Color brandPrimaryLight = Color(0xFFFFEDD5);
  static const Color brandSecondary = Color(0xFF0F172A); // Deep Slate / Obsidian Navy
  static const Color brandSecondaryLight = Color(0xFF1E293B);
  static const Color brandAccent = Color(0xFF10B981); // Fresh Emerald Green
  static const Color brandAccentLight = Color(0xFFD1FAE5);

  // Surface & Neutrals (Light Theme)
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocus = Color(0xFFF97316);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Dark Theme / Console Colors
  static const Color darkBg = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1F2937);
  static const Color darkBorder = Color(0xFF374151);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextMuted = Color(0xFF6B7280);

  // Backward Compatible Aliases
  static const Color primary = brandPrimary;
  static const Color primaryDark = brandSecondary;
  static const Color accent = brandAccent;
  static const Color warningBg = statusPendingBg;
  static const Color errorBg = statusCancelledBg;
  static const Color successBg = statusDeliveredBg;

  // Status & Semantic Feedback
  static const Color statusPendingBg = Color(0xFFFEF3C7);
  static const Color statusPendingFg = Color(0xFFD97706);
  static const Color statusAssignedBg = Color(0xFFE0E7FF);
  static const Color statusAssignedFg = Color(0xFF4F46E5);
  static const Color statusPickedUpBg = Color(0xFFE0F2FE);
  static const Color statusPickedUpFg = Color(0xFF0284C7);
  static const Color statusOnTheWayBg = Color(0xFFFCE7F3);
  static const Color statusOnTheWayFg = Color(0xFFDB2777);
  static const Color statusDeliveredBg = Color(0xFFD1FAE5);
  static const Color statusDeliveredFg = Color(0xFF059669);
  static const Color statusCancelledBg = Color(0xFFFEE2E2);
  static const Color statusCancelledFg = Color(0xFFDC2626);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Map & Live Tracking Palette
  static const Color mapBg = Color(0xFF0F172A);
  static const Color mapRiderMarker = Color(0xFFF97316);
  static const Color mapStoreMarker = Color(0xFF10B981);
  static const Color mapDestinationMarker = Color(0xFFEF4444);
  static const Color mapRoutePolyline = Color(0xFF38BDF8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFFB923C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient riderStatusGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
