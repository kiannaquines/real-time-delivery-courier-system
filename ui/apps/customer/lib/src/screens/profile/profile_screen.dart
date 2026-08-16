import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_session/auth_session.dart';
import 'package:design_system/design_system.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthSessionManager>();
    final user = auth.currentUser;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    user != null && user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? 'Customer', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(user?.email ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      if (user?.phone != null && user!.phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(user.phone, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                title: const Text('Saved Addresses'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(height: 1, color: AppColors.border),
              ListTile(
                leading: const Icon(Icons.help_outline, color: AppColors.primary),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(height: 1, color: AppColors.border),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('Log Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => const ConfirmationDialog(
                      title: 'Log Out',
                      content: 'Are you sure you want to sign out of your account?',
                      confirmText: 'Log Out',
                      isDestructive: true,
                    ),
                  );
                  if (confirmed == true) {
                    auth.logout();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
