import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<Order> _orders = [];
  List<RiderProfile> _riders = [];
  bool _isLoading = true;
  String? _error;
  OrderStatus? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final orders = await api.getOrders(status: _selectedStatusFilter);
      final riders = await api.getRiders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _riders = riders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAssignRiderDialog(Order order) async {
    final availableRiders = _riders.where((r) => r.status == RiderStatus.available).toList();

    if (availableRiders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available riders online at this moment.')),
      );
      return;
    }

    String? selectedRiderId = availableRiders.first.userId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => AlertDialog(
          title: Text('Assign Rider to ${order.orderNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Store: ${order.storeName ?? "M&S Store"}'),
              Text('Destination: ${order.deliveryAddress}'),
              const SizedBox(height: 16),
              const Text('Select Available Rider:', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedRiderId,
                items: availableRiders.map((r) => DropdownMenuItem(
                  value: r.userId,
                  child: Text('${r.fullName} (${r.vehicleType} - ${r.plateNumber})'),
                )).toList(),
                onChanged: (val) => setModalState(() => selectedRiderId = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(modalCtx).pop(false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.of(modalCtx).pop(true),
              child: const Text('Assign Rider'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedRiderId != null) {
      try {
        final api = context.read<ApiClient>();
        await api.assignOrder(order.id, selectedRiderId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rider assigned successfully!')),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to assign rider: $e')));
      }
    }
  }

  Future<void> _showCancelOrderDialog(Order order) async {
    final reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Order ${order.orderNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reason for cancellation:', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Store out of stock, customer requested cancel',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Back')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              if (reasonCtrl.text.trim().isNotEmpty) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonCtrl.text.trim().isNotEmpty) {
      try {
        final api = context.read<ApiClient>();
        await api.cancelOrder(order.id, reasonCtrl.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled.')),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cancellation failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.brandPrimary)));
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final padding = isMobile ? 16.0 : 24.0;

        return Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Responsive Filter & Action Toolbar
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<OrderStatus?>(
                            value: _selectedStatusFilter,
                            hint: const Text('All Orders'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Orders')),
                              ...OrderStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedStatusFilter = val);
                              _loadData();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                    onPressed: _loadData,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Responsive Horizontal & Vertical Scrollable Orders Data Table
              Expanded(
                child: _orders.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.inbox_outlined,
                        title: 'No Orders Found',
                        description: 'No orders currently match the selected status filter.',
                      )
                    : Card(
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
                                  DataColumn(label: Text('Order #', style: TextStyle(fontWeight: FontWeight.w800))),
                                  DataColumn(label: Text('Store', style: TextStyle(fontWeight: FontWeight.w800))),
                                  DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.w800))),
                                  DataColumn(label: Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w800))),
                                  DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.w800))),
                                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w800))),
                                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w800))),
                                ],
                                rows: _orders.map((o) {
                                  return DataRow(cells: [
                                    DataCell(Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brandPrimary))),
                                    DataCell(Text(o.storeName ?? '—')),
                                    DataCell(Text(o.customerName ?? '—')),
                                    DataCell(SizedBox(width: 180, child: Text(o.deliveryAddress, overflow: TextOverflow.ellipsis))),
                                    DataCell(Text(Formatters.currency(o.totalAmount), style: const TextStyle(fontWeight: FontWeight.w700))),
                                    DataCell(StatusBadge(status: o.status, isSmall: true)),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (o.status == OrderStatus.confirmed || o.status == OrderStatus.pending)
                                            OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                              ),
                                              icon: const Icon(Icons.person_add_rounded, size: 14),
                                              label: const Text('Assign'),
                                              onPressed: () => _showAssignRiderDialog(o),
                                            ),
                                          if (o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled) ...[
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 18),
                                              tooltip: 'Cancel Order',
                                              onPressed: () => _showCancelOrderDialog(o),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ]);
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
