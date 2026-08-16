import 'package:flutter/material.dart';
import 'package:domain_models/domain_models.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool isSmall;

  const StatusBadge({super.key, required this.status, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case OrderStatus.pending:
        bg = AppColors.statusPendingBg;
        fg = AppColors.statusPendingFg;
        icon = Icons.access_time;
        break;
      case OrderStatus.confirmed:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        icon = Icons.check_circle_outline;
        break;
      case OrderStatus.assigned:
        bg = AppColors.statusAssignedBg;
        fg = AppColors.statusAssignedFg;
        icon = Icons.person_pin_circle_outlined;
        break;
      case OrderStatus.pickedUp:
        bg = AppColors.statusPickedUpBg;
        fg = AppColors.statusPickedUpFg;
        icon = Icons.shopping_bag_outlined;
        break;
      case OrderStatus.onTheWay:
        bg = AppColors.statusOnTheWayBg;
        fg = AppColors.statusOnTheWayFg;
        icon = Icons.two_wheeler;
        break;
      case OrderStatus.delivered:
        bg = AppColors.statusDeliveredBg;
        fg = AppColors.statusDeliveredFg;
        icon = Icons.verified;
        break;
      case OrderStatus.cancelled:
        bg = AppColors.statusCancelledBg;
        fg = AppColors.statusCancelledFg;
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmall ? 12 : 14, color: fg),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: isSmall ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
