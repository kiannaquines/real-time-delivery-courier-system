import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';

class AdminRidersScreen extends StatefulWidget {
  const AdminRidersScreen({super.key});

  @override
  State<AdminRidersScreen> createState() => _AdminRidersScreenState();
}

class _AdminRidersScreenState extends State<AdminRidersScreen> {
  List<RiderProfile> _riders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRiders();
  }

  Future<void> _loadRiders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final riders = await api.getRiders();
      if (mounted) {
        setState(() {
          _riders = riders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCreateRiderDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'RiderPass123!');
    final plateCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Rider'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 12),
              TextField(controller: plateCtrl, decoration: const InputDecoration(labelText: 'Plate Number')),
              const SizedBox(height: 12),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty && plateCtrl.text.isNotEmpty) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Add Rider'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final api = context.read<ApiClient>();
        await api.createRider(
          fullName: nameCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          plateNumber: plateCtrl.text.trim(),
          password: passCtrl.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rider added successfully!')));
        _loadRiders();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to register: $e')));
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
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Riders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      Text('Riders registered in Kabacan (${_riders.length})', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: const Text('Add Rider'),
                    onPressed: _showCreateRiderDialog,
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
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text('Rider', style: TextStyle(fontWeight: FontWeight.w800))),
                            DataColumn(label: Text('Contact', style: TextStyle(fontWeight: FontWeight.w800))),
                            DataColumn(label: Text('Vehicle Info', style: TextStyle(fontWeight: FontWeight.w800))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w800))),
                            DataColumn(label: Text('Current Task', style: TextStyle(fontWeight: FontWeight.w800))),
                          ],
                          rows: _riders.map((r) {
                            return DataRow(
                              cells: [
                                DataCell(Text(r.fullName, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
                                DataCell(Text('${r.email}\n${r.phone}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                                DataCell(Text('${r.vehicleType} • ${r.plateNumber}', style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: r.status == RiderStatus.available
                                          ? AppColors.brandAccentLight
                                          : (r.status == RiderStatus.busy ? AppColors.brandPrimaryLight : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      r.status.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: r.status == RiderStatus.available
                                            ? AppColors.brandAccent
                                            : (r.status == RiderStatus.busy ? AppColors.brandPrimary : Colors.grey.shade700),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    r.activeDeliveryId != null ? 'On Delivery' : 'None',
                                    style: TextStyle(
                                      color: r.activeDeliveryId != null ? AppColors.brandPrimary : AppColors.textMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
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
