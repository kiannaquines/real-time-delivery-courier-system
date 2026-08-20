import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_session/auth_session.dart';
import 'package:design_system/design_system.dart';
import '../../state/location_engine.dart';

class RiderProfileScreen extends StatelessWidget {
  const RiderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthSessionManager>();
    final rider = auth.currentUser;
    final locationEngine = context.watch<LocationEngine>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rider Profile', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Avatar Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.premiumShadow,
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandPrimary.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      rider != null && rider.fullName.isNotEmpty ? rider.fullName[0].toUpperCase() : 'C',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  rider?.fullName ?? 'Carlos Swift',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  rider?.email ?? 'rider@mns.com',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 14, color: AppColors.brandPrimary),
                      SizedBox(width: 6),
                      Text('Verified Rider • Kabacan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.brandPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Vehicle Information Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vehicle & Account Info', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  _buildProfileRow(Icons.two_wheeler_rounded, 'Vehicle', 'Yamaha NMAX 155'),
                  const Divider(height: 20),
                  _buildProfileRow(Icons.pin_rounded, 'Plate Number', 'MNS-7788 (Registered)'),
                  const Divider(height: 20),
                  _buildProfileRow(Icons.location_on_rounded, 'Location', 'Poblacion, Kabacan, Cotabato'),
                  const Divider(height: 20),
                  _buildProfileRow(Icons.star_rounded, 'Rating', '★ 4.9 Rating (100% On-Time)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sign Out Action Button
          AppButton(
            text: 'Log Out',
            variant: ButtonVariant.danger,
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => const ConfirmationDialog(
                  title: 'Log Out',
                  content: 'Are you sure you want to log out?',
                  confirmText: 'Log Out',
                  isDestructive: true,
                ),
              );
              if (confirmed == true) {
                locationEngine.stopTracking();
                auth.logout();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.brandPrimaryLight, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: AppColors.brandPrimary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
