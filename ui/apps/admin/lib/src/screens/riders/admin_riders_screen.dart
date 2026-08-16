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
        title: const Text('Add New Fleet Courier'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Rider Full Name')),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 12),
              TextField(controller: plateCtrl, decoration: const InputDecoration(labelText: 'Vehicle Plate Number')),
              const SizedBox(height: 12),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Initial Password'), obscureText: true),
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
            child: const Text('Register Rider'),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rider registered successfully!')));
        _loadRiders();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active Fleet (${_riders.length} couriers)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Register Rider'),
                onPressed: _showCreateRiderDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Rider Name', style: TextStyle(fontWeight: FontWeight.w700))),
                    DataColumn(label: Text('Contact', style: TextStyle(fontWeight: FontWeight.w700))),
                    DataColumn(label: Text('Vehicle & Plate', style: TextStyle(fontWeight: FontWeight.w700))),
                    DataColumn(label: Text('Duty Status', style: TextStyle(fontWeight: FontWeight.w700))),
                    DataColumn(label: Text('Active Task', style: TextStyle(fontWeight: FontWeight.w700))),
                  ],
                  rows: _riders.map((r) {
                    return DataRow(
                      cells: [
                        DataCell(Text(r.fullName, style: const TextStyle(fontWeight: FontWeight.w700))),
                        DataCell(Text('${r.email}\n${r.phone}', style: const TextStyle(fontSize: 12))),
                        DataCell(Text('${r.vehicleType} • ${r.plateNumber}')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: r.status == RiderStatus.available
                                  ? AppColors.successBg
                                  : (r.status == RiderStatus.busy ? AppColors.warningBg : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              r.status.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: r.status == RiderStatus.available
                                    ? AppColors.primary
                                    : (r.status == RiderStatus.busy ? const Color(0xFF856404) : Colors.grey.shade700),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            r.activeDeliveryId != null ? 'Delivery In Progress' : 'None (Idle)',
                            style: TextStyle(
                              color: r.activeDeliveryId != null ? AppColors.primary : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}
