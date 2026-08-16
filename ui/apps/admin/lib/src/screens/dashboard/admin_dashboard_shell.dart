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

class AdminDashboardShell extends StatefulWidget {
  const AdminDashboardShell({super.key});

  @override
  State<AdminDashboardShell> createState() => _AdminDashboardShellState();
}

class _AdminDashboardShellState extends State<AdminDashboardShell> {
  int _selectedIndex = 0;

  final _navItems = const [
    {'title': 'Operations Overview', 'icon': Icons.dashboard_outlined, 'selectedIcon': Icons.dashboard},
    {'title': 'Dispatch & Orders', 'icon': Icons.assignment_outlined, 'selectedIcon': Icons.assignment},
    {'title': 'Stores & Inventory', 'icon': Icons.storefront_outlined, 'selectedIcon': Icons.storefront},
    {'title': 'Rider Fleet', 'icon': Icons.two_wheeler_outlined, 'selectedIcon': Icons.two_wheeler},
    {'title': 'Live Fleet Map', 'icon': Icons.map_outlined, 'selectedIcon': Icons.map},
    {'title': 'Reports & Analytics', 'icon': Icons.analytics_outlined, 'selectedIcon': Icons.analytics},
    {'title': 'Audit & Compliance', 'icon': Icons.security_outlined, 'selectedIcon': Icons.security},
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthSessionManager>();
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    final pages = [
      AdminOverviewDashboard(onNavigateTab: (idx) => setState(() => _selectedIndex = idx)),
      const AdminOrdersScreen(),
      const AdminStoresScreen(),
      const AdminRidersScreen(),
      const AdminLiveMapScreen(),
      const AdminReportsScreen(),
      const AdminAuditLogsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            extended: isDesktop,
            minExtendedWidth: 230,
            backgroundColor: AppColors.brandSecondary,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandPrimary.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.delivery_dining, color: Colors.white, size: 22),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'M&S Kabacan',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.3),
                        ),
                        Text(
                          'Command Console',
                          style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w500, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    tooltip: 'Sign Out Console',
                    onPressed: () => auth.logout(),
                  ),
                ),
              ),
            ),
            destinations: _navItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item['icon'] as IconData, color: Colors.white60),
                selectedIcon: Icon(item['selectedIcon'] as IconData, color: AppColors.brandPrimary),
                label: Text(
                  item['title'] as String,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              );
            }).toList(),
          ),

          // Main Content View
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            _navItems[_selectedIndex]['title'] as String,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.3),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.brandAccentLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 8, color: AppColors.brandAccent),
                                SizedBox(width: 6),
                                Text('Live Engine Connected', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brandAccent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none_outlined, color: AppColors.textSecondary),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.brandPrimary.withOpacity(0.15),
                                  child: const Text('A', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.brandPrimary, fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                const Text('Head Admin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Selected Tab Body
                Expanded(child: pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
