import 'package:flutter/material.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  final List<Map<String, dynamic>> _auditLogs = [
    {
      'actor': 'admin@mns.com',
      'action': 'order.assign_rider',
      'target': 'MNS-260816-A102',
      'reason': 'Assigned to Carlos Swift Rider (Yamaha NMAX 155)',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
      'severity': 'info'
    },
    {
      'actor': 'admin@mns.com',
      'action': 'store.update_menu',
      'target': 'Rose Garden Restaurant',
      'reason': 'Price matrix updated for Classic Cheeseburger Deluxe',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 25)),
      'severity': 'info'
    },
    {
      'actor': 'admin@mns.com',
      'action': 'order.cancel',
      'target': 'MNS-260816-F981',
      'reason': 'Customer requested change of delivery address to Purok Miracle',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 12)),
      'severity': 'warning'
    },
    {
      'actor': 'admin@mns.com',
      'action': 'rider.register',
      'target': 'Carlos Swift Rider',
      'reason': 'Verified driver license and plate MNS-7788 registration',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2, minutes: 40)),
      'severity': 'success'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 16.0 : 24.0;

        return Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Activity Logs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                      SizedBox(height: 4),
                      Text('History of admin actions and system events.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Export Logs'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logs exported successfully.')));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth - (padding * 2)),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                          horizontalMargin: 16,
                          columnSpacing: 22,
                          columns: const [
                            DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.w800))),
                            DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.w800))),
                            DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.w800))),
                            DataColumn(label: Text('Target', style: TextStyle(fontWeight: FontWeight.w800))),
                            DataColumn(label: Text('Details', style: TextStyle(fontWeight: FontWeight.w800))),
                          ],
                          rows: _auditLogs.map((log) {
                            final dt = log['timestamp'] as DateTime;
                            final severity = log['severity'] as String;
                            Color badgeBg = AppColors.brandPrimaryLight;
                            Color badgeFg = AppColors.brandPrimary;

                            if (severity == 'warning') {
                              badgeBg = const Color(0xFFFEF3C7);
                              badgeFg = const Color(0xFFD97706);
                            } else if (severity == 'success') {
                              badgeBg = AppColors.brandAccentLight;
                              badgeFg = AppColors.brandAccent;
                            }

                            return DataRow(
                              cells: [
                                DataCell(Text(Formatters.dateTime(dt), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                                DataCell(Text(log['actor'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                                    child: Text(log['action'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: badgeFg)),
                                  ),
                                ),
                                DataCell(Text(log['target'] as String, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
                                DataCell(SizedBox(width: 260, child: Text(log['reason'] as String, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
