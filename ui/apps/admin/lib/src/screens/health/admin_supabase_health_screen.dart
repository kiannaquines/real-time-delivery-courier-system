import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:design_system/design_system.dart';

class AdminSupabaseHealthScreen extends StatefulWidget {
  const AdminSupabaseHealthScreen({super.key});

  @override
  State<AdminSupabaseHealthScreen> createState() => _AdminSupabaseHealthScreenState();
}

class _AdminSupabaseHealthScreenState extends State<AdminSupabaseHealthScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _healthData;
  DateTime? _lastRefreshed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHealthData();
    });
  }

  Future<void> _fetchHealthData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = context.read<ApiClient>();
      final data = await client.getSupabaseHealth();
      if (mounted) {
        setState(() {
          _healthData = data;
          _isLoading = false;
          _lastRefreshed = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _healthData == null) {
      return const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.brandPrimary)),
      );
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isNarrow = constraints.maxWidth < 950;
        final padding = isMobile ? 16.0 : (isNarrow ? 20.0 : 28.0);

        final db = _healthData?['database'] as Map<String, dynamic>? ?? {};
        final totalRecords = db['total_records']?.toString() ?? '0';
        final latency = (_healthData?['latency_ms'] as num?)?.toDouble() ?? 0.0;
        final engineType = db['type']?.toString() ?? 'PostgreSQL';
        final host = db['host']?.toString() ?? 'aws-0-ap-northeast-1.pooler.supabase.com';

        final card1 = _buildMetricCard(
          'Database Engine',
          engineType,
          'Supabase Cloud',
          Icons.dns_rounded,
          AppColors.brandPrimary,
        );
        final card2 = _buildMetricCard(
          'Network Latency',
          '${latency.toStringAsFixed(1)} ms',
          latency < 500 ? 'Optimal Ping' : 'Cloud Interconnect',
          Icons.speed_rounded,
          AppColors.brandAccent,
        );
        final card3 = _buildMetricCard(
          'Persisted Records',
          totalRecords,
          '16 tables active',
          Icons.table_chart_rounded,
          const Color(0xFF6366F1),
        );
        final card4 = _buildMetricCard(
          'Active Pooler Port',
          host.contains(':') ? host.split(':')[1] : '5432',
          host.split(':')[0],
          Icons.cloud_done_rounded,
          AppColors.warning,
        );

        return Padding(
          padding: EdgeInsets.all(padding),
          child: ListView(
            children: [
              // Page Header
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 14,
                runSpacing: 14,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Supabase Cluster Health',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _lastRefreshed != null
                            ? 'Live PostgreSQL diagnostics • Last ping: ${_lastRefreshed!.hour.toString().padLeft(2, '0')}:${_lastRefreshed!.minute.toString().padLeft(2, '0')}:${_lastRefreshed!.second.toString().padLeft(2, '0')}'
                            : 'Live PostgreSQL cluster diagnostics, telemetry latency, and schema metrics.',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(_isLoading ? 'Pinging...' : 'Test Connection'),
                    onPressed: _isLoading ? null : _fetchHealthData,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null && _healthData == null)
                _buildErrorCard()
              else ...[
                // Main Status Banner
                _buildStatusBanner(),
                const SizedBox(height: 20),

                // Responsive KPI Cards
                if (isMobile) ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(width: constraints.maxWidth - (padding * 2), child: card1),
                      SizedBox(width: constraints.maxWidth - (padding * 2), child: card2),
                      SizedBox(width: constraints.maxWidth - (padding * 2), child: card3),
                      SizedBox(width: constraints.maxWidth - (padding * 2), child: card4),
                    ],
                  ),
                ] else if (isNarrow) ...[
                  Row(children: [Expanded(child: card1), const SizedBox(width: 14), Expanded(child: card2)]),
                  const SizedBox(height: 14),
                  Row(children: [Expanded(child: card3), const SizedBox(width: 14), Expanded(child: card4)]),
                ] else ...[
                  Row(
                    children: [
                      Expanded(child: card1),
                      const SizedBox(width: 16),
                      Expanded(child: card2),
                      const SizedBox(width: 16),
                      Expanded(child: card3),
                      const SizedBox(width: 16),
                      Expanded(child: card4),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // Tables Inventory & Cluster Configuration Cards
                if (!isNarrow)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildTableInventoryCard(constraints, padding, isNarrow)),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: _buildCloudAndPoolDetailsCard()),
                    ],
                  )
                else ...[
                  _buildTableInventoryCard(constraints, padding, isNarrow),
                  const SizedBox(height: 24),
                  _buildCloudAndPoolDetailsCard(),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final db = _healthData?['database'] as Map<String, dynamic>? ?? {};
    final isConnected = db['connected'] == true;
    final latency = (_healthData?['latency_ms'] as num?)?.toDouble() ?? 0.0;
    final status = _healthData?['status']?.toString().toUpperCase() ?? 'HEALTHY';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isConnected ? AppColors.brandAccentLight : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isConnected ? AppColors.brandAccent : AppColors.error,
            child: Icon(
              isConnected ? Icons.check_rounded : Icons.priority_high_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isConnected ? 'Supabase PostgreSQL Online' : 'Database Disconnected',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isConnected ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isConnected ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isConnected ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isConnected
                      ? 'Roundtrip ping: ${latency.toStringAsFixed(1)} ms • Connected via transaction pooler.'
                      : 'Error: ${db['error'] ?? 'Connection timed out'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isConnected ? const Color(0xFF047857) : const Color(0xFF991B1B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableInventoryCard(BoxConstraints constraints, double padding, bool isNarrow) {
    final tables = _healthData?['tables'] as Map<String, dynamic>? ?? {};

    final tableMeta = [
      {'key': 'users', 'name': 'Users & Auth', 'desc': 'Admins, Riders, Customers'},
      {'key': 'rider_profiles', 'name': 'Rider Profiles', 'desc': 'Vehicles, GPS, status'},
      {'key': 'stores', 'name': 'Stores & Kitchens', 'desc': 'Partner restaurants'},
      {'key': 'menu_categories', 'name': 'Menu Categories', 'desc': 'Catalog taxonomy'},
      {'key': 'menu_items', 'name': 'Menu Catalog Items', 'desc': 'Foods, pricing & availability'},
      {'key': 'orders', 'name': 'Customer Orders', 'desc': 'Active & completed orders'},
      {'key': 'order_items', 'name': 'Order Line Items', 'desc': 'Items per transaction'},
      {'key': 'deliveries', 'name': 'Active Deliveries', 'desc': 'Dispatch & fulfillment'},
      {'key': 'rider_locations', 'name': 'GPS Route Telemetry', 'desc': 'Live coordinates & history'},
      {'key': 'payments', 'name': 'Payment Ledger', 'desc': 'COD & online receipts'},
      {'key': 'addresses', 'name': 'Saved Addresses', 'desc': 'Customer drop-off points'},
      {'key': 'refresh_tokens', 'name': 'Active Sessions', 'desc': 'JWT refresh tokens'},
      {'key': 'outbox_events', 'name': 'WebSocket Outbox', 'desc': 'Realtime broadcast events'},
      {'key': 'audit_logs', 'name': 'Audit Logs', 'desc': 'Security & system history'},
      {'key': 'idempotency_keys', 'name': 'Idempotency Keys', 'desc': 'Double-charge prevention'},
      {'key': 'device_tokens', 'name': 'Push Device Tokens', 'desc': 'FCM / APNs notifications'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    Text(
                      'Supabase Schema Inventory',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Live record counts synchronized across all 16 PostgreSQL tables',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '16 Tables Active',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.brandPrimary),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: isNarrow ? constraints.maxWidth - (padding * 2) - 40 : constraints.maxWidth - 440,
                ),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  columns: const [
                    DataColumn(label: Text('Table Name', style: TextStyle(fontWeight: FontWeight.w800))),
                    DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.w800))),
                    DataColumn(label: Text('Records', style: TextStyle(fontWeight: FontWeight.w800))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w800))),
                  ],
                  rows: tableMeta.map((item) {
                    final key = item['key'] as String;
                    final name = item['name'] as String;
                    final desc = item['desc'] as String;
                    final count = tables[key] ?? 0;

                    return DataRow(cells: [
                      DataCell(Row(
                        children: [
                          Icon(Icons.table_chart_outlined, size: 16, color: AppColors.brandPrimary),
                          const SizedBox(width: 8),
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      )),
                      DataCell(Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                      DataCell(Text(
                        '$count',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      )),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: count > 0 ? AppColors.brandAccentLight : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            count > 0 ? 'Synchronized' : 'Ready',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: count > 0 ? AppColors.brandAccent : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudAndPoolDetailsCard() {
    final sup = _healthData?['supabase'] as Map<String, dynamic>? ?? {};
    final db = _healthData?['database'] as Map<String, dynamic>? ?? {};
    final pool = db['pool'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        // Supabase Project Info Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cloud_queue_rounded, size: 20, color: AppColors.brandPrimary),
                    SizedBox(width: 10),
                    Text(
                      'Supabase Project Info',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildDetailRow('Project Ref', sup['project_ref'] ?? 'llumlzzczufzgjtvzhuc', canCopy: true),
                _buildDetailRow('REST API Engine', sup['auth_status'] ?? 'Active'),
                _buildDetailRow('Storage Bucket', sup['storage_bucket'] ?? 'menu-images'),
                _buildDetailRow('Storage Status', sup['storage_status'] ?? 'Ready'),
                _buildDetailRow('Target DB', db['database_name'] ?? 'postgres'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Connection Pool Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 20, color: AppColors.brandAccent),
                    SizedBox(width: 10),
                    Text(
                      'Engine & Pool Settings',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildDetailRow('Dialect', pool['engine'] ?? 'postgresql'),
                _buildDetailRow('Driver', pool['driver'] ?? 'psycopg2'),
                _buildDetailRow('Pool Size', '${pool['pool_size'] ?? 10} conns'),
                _buildDetailRow('Max Overflow', '+${pool['max_overflow'] ?? 20} burst'),
                _buildDetailRow('Pool Pre-Ping', 'Enabled'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(
                value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              if (canCopy) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
                    );
                  },
                  child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 14),
            const Text(
              'Could Not Fetch Health Metrics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown connection error.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _fetchHealthData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
