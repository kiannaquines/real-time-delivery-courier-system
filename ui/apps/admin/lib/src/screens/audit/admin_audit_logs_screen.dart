import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  // Simulated structured audit events
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
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Audit & Compliance Trail', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Immutable chronological log of all administrative actions and sensitive overrides.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export Audit Log'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audit log exported successfully.')));
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.w700))),
                    DataColumn(label: Text('Actor', style: TextStyle(fontWeight: FontWeight.w700))),
                    DataColumn(label: Text('Action Type', style: TextStyle(fontWeight: FontWeight.w700))),
                    DataColumn(label: Text('Target Entity', style: TextStyle(fontWeight: FontWeight.w700))),
                    DataColumn(label: Text('Reason & Metadata', style: TextStyle(fontWeight: FontWeight.w700))),
                  ],
                  rows: _auditLogs.map((log) {
                    final dt = log['timestamp'] as DateTime;
                    final severity = log['severity'] as String;
                    Color badgeBg = AppColors.brandPrimaryLight;
                    Color badgeFg = AppColors.brandPrimary;
                    if (severity == 'warning') {
                      badgeBg = AppColors.statusPendingBg;
                      badgeFg = AppColors.statusPendingFg;
                    } else if (severity == 'success') {
                      badgeBg = AppColors.statusDeliveredBg;
                      badgeFg = AppColors.statusDeliveredFg;
                    }

                    return DataRow(
                      cells: [
                        DataCell(Text(Formatters.dateTime(dt), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                        DataCell(Text(log['actor'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                            child: Text(log['action'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: badgeFg)),
                          ),
                        ),
                        DataCell(Text(log['target'] as String, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(log['reason'] as String, style: const TextStyle(fontSize: 13))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
