import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ButtonVariant { primary, secondary, outline, danger, ghost }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final bool useGradient;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 48,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.brandPrimary;
    Color fg = Colors.white;
    BorderSide border = BorderSide.none;
    Gradient? gradient;

    switch (variant) {
      case ButtonVariant.primary:
        bg = AppColors.brandPrimary;
        fg = Colors.white;
        if (useGradient && !isLoading && onPressed != null) {
          gradient = AppColors.primaryGradient;
        }
        break;
      case ButtonVariant.secondary:
        bg = AppColors.brandSecondary;
        fg = Colors.white;
        break;
      case ButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.brandPrimary;
        border = const BorderSide(color: AppColors.brandPrimary, width: 1.5);
        break;
      case ButtonVariant.danger:
        bg = AppColors.error;
        fg = Colors.white;
        break;
      case ButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.textPrimary;
        break;
    }

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ],
    );

    Widget btn;
    if (gradient != null) {
      btn = Container(
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandPrimary.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isLoading ? null : onPressed,
            child: Center(child: child),
          ),
        ),
      );
    } else {
      btn = SizedBox(
        height: height,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: border,
            ),
          ),
          child: child,
        ),
      );
    }

    if (width != null) {
      return SizedBox(width: width, child: btn);
    }
    return btn;
  }
}
