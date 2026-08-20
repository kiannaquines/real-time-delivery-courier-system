import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_session/auth_session.dart';
import 'package:design_system/design_system.dart';
import '../overview/admin_overview_dashboard.dart';
import '../orders/admin_orders_screen.dart';
import '../stores/admin_stores_screen.dart';
import '../riders/admin_riders_screen.dart';
import '../live_map/admin_live_map_screen.dart';
import '../reports/admin_reports_screen.dart';
import '../audit/admin_audit_logs_screen.dart';
import '../health/admin_supabase_health_screen.dart';

class AdminDashboardShell extends StatefulWidget {
  const AdminDashboardShell({super.key});

  @override
  State<AdminDashboardShell> createState() => _AdminDashboardShellState();
}

class _AdminDashboardShellState extends State<AdminDashboardShell> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _navItems = const [
    {
      'title': 'Overview',
      'icon': Icons.dashboard_outlined,
      'selectedIcon': Icons.dashboard_rounded,
    },
    {
      'title': 'Orders',
      'icon': Icons.receipt_long_outlined,
      'selectedIcon': Icons.receipt_long_rounded,
    },
    {
      'title': 'Stores',
      'icon': Icons.storefront_outlined,
      'selectedIcon': Icons.storefront_rounded,
    },
    {
      'title': 'Riders',
      'icon': Icons.two_wheeler_outlined,
      'selectedIcon': Icons.two_wheeler_rounded,
    },
    {
      'title': 'Live Map',
      'icon': Icons.map_outlined,
      'selectedIcon': Icons.map_rounded,
    },
    {
      'title': 'Reports',
      'icon': Icons.bar_chart_outlined,
      'selectedIcon': Icons.bar_chart_rounded,
    },
    {
      'title': 'Activity Logs',
      'icon': Icons.security_outlined,
      'selectedIcon': Icons.security_rounded,
    },
    {
      'title': 'Supabase Health',
      'icon': Icons.storage_outlined,
      'selectedIcon': Icons.storage_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthSessionManager>();
    final user = auth.currentUser;

    final pages = [
      AdminOverviewDashboard(onNavigateTab: (index) => setState(() => _selectedIndex = index)),
      const AdminOrdersScreen(),
      const AdminStoresScreen(),
      const AdminRidersScreen(),
      const AdminLiveMapScreen(),
      const AdminReportsScreen(),
      const AdminAuditLogsScreen(),
      const AdminSupabaseHealthScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final isCompactScreen = constraints.maxWidth < 800;
          final isMobileScreen = constraints.maxWidth < 600;

          return Row(
            children: [
              // Responsive Navigation Rail (Icons-only on compact/tablet, Extended on desktop)
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
                extended: constraints.maxWidth >= 1200,
                minExtendedWidth: 240,
                minWidth: 68,
                backgroundColor: Colors.white,
                indicatorColor: AppColors.brandPrimaryLight,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandPrimary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 22),
                      ),
                      if (constraints.maxWidth >= 1200) ...[
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'M&S Express',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Admin Portal',
                              style: TextStyle(
                                color: AppColors.brandPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                destinations: _navItems.map((item) {
                  return NavigationRailDestination(
                    icon: Icon(item['icon'] as IconData, color: AppColors.textSecondary, size: 22),
                    selectedIcon: Icon(item['selectedIcon'] as IconData, color: AppColors.brandPrimary, size: 22),
                    label: Text(
                      item['title'] as String,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const VerticalDivider(thickness: 1, width: 1, color: AppColors.border),

              // Main Content Area with Adaptive Top Header
              Expanded(
                child: Column(
                  children: [
                    // Adaptive Top Header Bar
                    Container(
                      height: 68,
                      padding: EdgeInsets.symmetric(horizontal: isMobileScreen ? 14 : 24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Page Title & Status Pill (Truncated if space is tight)
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _navItems[_selectedIndex]['title'] as String,
                                    style: TextStyle(
                                      fontSize: isMobileScreen ? 16 : 19,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!isMobileScreen) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandPrimaryLight,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.brandPrimary.withOpacity(0.25)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.circle, size: 7, color: AppColors.brandPrimary),
                                        SizedBox(width: 6),
                                        Text(
                                          'System Active',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.brandPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Right Controls & User Profile Pill
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
                                  tooltip: 'Refresh',
                                  onPressed: () => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // User Profile Dropdown Button
                              PopupMenuButton<String>(
                                position: PopupMenuPosition.under,
                                offset: const Offset(0, 8),
                                elevation: 8,
                                shadowColor: Colors.black.withOpacity(0.15),
                                surfaceTintColor: Colors.white,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: AppColors.border),
                                ),
                                onSelected: (val) {
                                  if (val == 'logout') auth.logout();
                                },
                                itemBuilder: (ctx) => [
                                  PopupMenuItem<String>(
                                    enabled: false,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user?.fullName ?? 'Administrator',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          user?.email ?? 'admin@mns.com',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem<String>(
                                    value: 'logout',
                                    child: Row(
                                      children: [
                                        Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                                        SizedBox(width: 10),
                                        Text(
                                          'Log Out',
                                          style: TextStyle(
                                            color: AppColors.error,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: isMobileScreen ? 6 : 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                    boxShadow: AppColors.premiumShadow,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppColors.brandPrimaryLight,
                                        child: Text(
                                          user != null && user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'A',
                                          style: const TextStyle(
                                            color: AppColors.brandPrimary,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      if (!isMobileScreen) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          user?.fullName ?? 'Admin',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary, size: 18),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Active View
                    Expanded(child: pages[_selectedIndex]),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
