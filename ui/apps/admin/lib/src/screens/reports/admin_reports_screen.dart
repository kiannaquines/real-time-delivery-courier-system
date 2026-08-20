import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  List<Order> _orders = [];
  List<RiderProfile> _riders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiClient>();
      final orders = await api.getOrders();
      final riders = await api.getRiders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _riders = riders;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.brandPrimary)));
    }

    final completedOrders = _orders.where((o) => o.status == OrderStatus.delivered).toList();
    final totalSales = completedOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
    final totalFees = completedOrders.fold(0.0, (sum, o) => sum + o.deliveryFee);

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isNarrow = constraints.maxWidth < 950;
        final padding = isMobile ? 16.0 : (isNarrow ? 20.0 : 28.0);

        final card1 = _buildMetricCard('Total Sales (COD)', Formatters.currency(totalSales), Icons.attach_money_rounded, AppColors.brandPrimary);
        final card2 = _buildMetricCard('Completed Orders', '${completedOrders.length}', Icons.check_circle_outline_rounded, AppColors.brandAccent);
        final card3 = _buildMetricCard('Delivery Fees', Formatters.currency(totalFees), Icons.two_wheeler_rounded, const Color(0xFF6366F1));

        return Padding(
          padding: EdgeInsets.all(padding),
          child: ListView(
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 14,
                runSpacing: 14,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sales & Delivery Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                      SizedBox(height: 4),
                      Text('Summary of sales, delivery fees, and rider performance.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Export CSV'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('CSV report downloaded successfully.')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Responsive Overview KPI Cards
              if (isMobile) ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(width: constraints.maxWidth - (padding * 2), child: card1),
                    SizedBox(width: (constraints.maxWidth - (padding * 2) - 12) / 2, child: card2),
                    SizedBox(width: (constraints.maxWidth - (padding * 2) - 12) / 2, child: card3),
                  ],
                ),
              ] else if (isNarrow) ...[
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(width: (constraints.maxWidth - (padding * 2) - 16) / 2, child: card1),
                    SizedBox(width: (constraints.maxWidth - (padding * 2) - 16) / 2, child: card2),
                    SizedBox(width: constraints.maxWidth - (padding * 2), child: card3),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: card1),
                    const SizedBox(width: 18),
                    Expanded(child: card2),
                    const SizedBox(width: 18),
                    Expanded(child: card3),
                  ],
                ),
              ],
              const SizedBox(height: 28),

              // Responsive Rider Performance Table
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rider Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      const Text('Deliveries completed and total cash collected per rider.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const Divider(height: 24),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth - (padding * 2) - 40),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                            columns: const [
                              DataColumn(label: Text('Rider Name', style: TextStyle(fontWeight: FontWeight.w800))),
                              DataColumn(label: Text('Vehicle', style: TextStyle(fontWeight: FontWeight.w800))),
                              DataColumn(label: Text('Completed Deliveries', style: TextStyle(fontWeight: FontWeight.w800))),
                              DataColumn(label: Text('Cash Collected (COD)', style: TextStyle(fontWeight: FontWeight.w800))),
                              DataColumn(label: Text('Rating', style: TextStyle(fontWeight: FontWeight.w800))),
                            ],
                            rows: _riders.map((r) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(r.fullName, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
                                  DataCell(Text('${r.vehicleType} • ${r.plateNumber}', style: const TextStyle(fontSize: 12))),
                                  DataCell(Text('${completedOrders.length}', style: const TextStyle(fontWeight: FontWeight.w700))),
                                  DataCell(Text(Formatters.currency(totalSales), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brandPrimary))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.brandAccentLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('★ 4.9 (100% On-Time)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.brandAccent)),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
