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
    _fetchHealthData();
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
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final padding = isMobile ? 16.0 : 24.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Refresh Row
              _buildHeader(isMobile),
              const SizedBox(height: 24),

              if (_isLoading && _healthData == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Pinging Supabase PostgreSQL & Services...',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_errorMessage != null && _healthData == null)
                _buildErrorCard()
              else ...[
                // Main Status Banner
                _buildStatusBanner(isMobile),
                const SizedBox(height: 20),

                // 4 Key KPI Metrics Cards
                _buildMetricsGrid(constraints),
                const SizedBox(height: 24),

                // Two Columns: Table Inventory & Cloud Services
                if (constraints.maxWidth >= 1000)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildTableInventoryCard()),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: _buildCloudAndPoolDetailsCard()),
                    ],
                  )
                else ...[
                  _buildTableInventoryCard(),
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

  Widget _buildHeader(bool isMobile) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF3ECF8E).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.storage_rounded,
                color: Color(0xFF10B981),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Supabase Cluster Health',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  _lastRefreshed != null
                      ? 'Last ping: ${_lastRefreshed!.hour.toString().padLeft(2, '0')}:${_lastRefreshed!.minute.toString().padLeft(2, '0')}:${_lastRefreshed!.second.toString().padLeft(2, '0')}'
                      : 'Live PostgreSQL Diagnostics',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _fetchHealthData,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.refresh_rounded, size: 18),
          label: Text(_isLoading ? 'Pinging...' : 'Test Connection'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner(bool isMobile) {
    final db = _healthData?['database'] as Map<String, dynamic>? ?? {};
    final isConnected = db['connected'] == true;
    final latency = (_healthData?['latency_ms'] as num?)?.toDouble() ?? 0.0;
    final status = _healthData?['status']?.toString().toUpperCase() ?? 'UNKNOWN';

    final isHealthy = isConnected && status == 'HEALTHY';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isConnected ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isConnected ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white,
              size: 26,
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
                      isConnected ? 'Supabase PostgreSQL is Connected' : 'Database Connection Issue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isConnected ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                      ? 'Live roundtrip latency: ${latency.toStringAsFixed(1)} ms • Direct communication with cloud database active.'
                      : 'Error: ${db['error'] ?? 'Could not reach database'}',
                  style: TextStyle(
                    fontSize: 13,
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

  Widget _buildMetricsGrid(BoxConstraints constraints) {
    final db = _healthData?['database'] as Map<String, dynamic>? ?? {};
    final totalRecords = db['total_records']?.toString() ?? '0';
    final latency = (_healthData?['latency_ms'] as num?)?.toDouble() ?? 0.0;
    final engineType = db['type']?.toString() ?? 'PostgreSQL';
    final host = db['host']?.toString() ?? 'localhost';

    final isWide = constraints.maxWidth >= 1000;
    final isTablet = constraints.maxWidth >= 600 && !isWide;

    final cards = [
      _buildMetricCard(
        title: 'Database Engine',
        value: engineType,
        subtitle: 'Managed Supabase',
        icon: Icons.dns_rounded,
        iconColor: const Color(0xFF3B82F6),
        bgColor: const Color(0xFFEFF6FF),
      ),
      _buildMetricCard(
        title: 'Network Ping Latency',
        value: '${latency.toStringAsFixed(1)} ms',
        subtitle: latency < 100 ? 'Optimal Performance' : 'Cloud Interconnect',
        icon: Icons.speed_rounded,
        iconColor: const Color(0xFF10B981),
        bgColor: const Color(0xFFECFDF5),
      ),
      _buildMetricCard(
        title: 'Total Persisted Records',
        value: totalRecords,
        subtitle: 'Across 16 schema tables',
        icon: Icons.table_chart_rounded,
        iconColor: const Color(0xFF8B5CF6),
        bgColor: const Color(0xFFF5F3FF),
      ),
      _buildMetricCard(
        title: 'Active Connection Host',
        value: host.split(':')[0],
        subtitle: 'Port: ${host.contains(':') ? host.split(':')[1] : '5432'}',
        icon: Icons.cloud_done_rounded,
        iconColor: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFFFBEB),
      ),
    ];

    if (isWide) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
      );
    } else if (isTablet) {
      return Column(
        children: [
          Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])]),
        ],
      );
    } else {
      return Column(
        children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
      );
    }
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildTableInventoryCard() {
    final tables = _healthData?['tables'] as Map<String, dynamic>? ?? {};

    final tableMeta = [
      {'key': 'users', 'name': 'Users & Auth', 'icon': Icons.people_outline},
      {'key': 'rider_profiles', 'name': 'Rider Profiles', 'icon': Icons.badge_outlined},
      {'key': 'stores', 'name': 'Stores & Kitchens', 'icon': Icons.store_mall_directory_outlined},
      {'key': 'menu_categories', 'name': 'Menu Categories', 'icon': Icons.category_outlined},
      {'key': 'menu_items', 'name': 'Menu Catalog Items', 'icon': Icons.restaurant_menu_outlined},
      {'key': 'orders', 'name': 'Customer Orders', 'icon': Icons.receipt_outlined},
      {'key': 'order_items', 'name': 'Order Line Items', 'icon': Icons.list_alt_outlined},
      {'key': 'deliveries', 'name': 'Active Deliveries', 'icon': Icons.local_shipping_outlined},
      {'key': 'rider_locations', 'name': 'GPS Telemetry History', 'icon': Icons.location_on_outlined},
      {'key': 'payments', 'name': 'Payment Ledger', 'icon': Icons.payments_outlined},
      {'key': 'addresses', 'name': 'Customer Addresses', 'icon': Icons.place_outlined},
      {'key': 'refresh_tokens', 'name': 'Active Sessions', 'icon': Icons.key_outlined},
      {'key': 'outbox_events', 'name': 'WebSocket Outbox', 'icon': Icons.sync_alt_outlined},
      {'key': 'audit_logs', 'name': 'System Audit Logs', 'icon': Icons.security_outlined},
      {'key': 'idempotency_keys', 'name': 'API Idempotency Keys', 'icon': Icons.fingerprint_outlined},
      {'key': 'device_tokens', 'name': 'Push Device Tokens', 'icon': Icons.notifications_none_outlined},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Supabase Schema Inventory',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${tableMeta.length} Tables Active',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Live record counts from Supabase PostgreSQL tables',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Divider(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisExtent: 64,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: tableMeta.length,
            itemBuilder: (ctx, idx) {
              final item = tableMeta[idx];
              final key = item['key'] as String;
              final count = tables[key] ?? 0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData, size: 18, color: const Color(0xFF10B981)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['name'] as String,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            key,
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCloudAndPoolDetailsCard() {
    final sup = _healthData?['supabase'] as Map<String, dynamic>? ?? {};
    final db = _healthData?['database'] as Map<String, dynamic>? ?? {};
    final pool = db['pool'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        // Supabase Cloud Configuration
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.network(
                    'https://supabase.com/favicon/favicon-32x32.png',
                    width: 20,
                    height: 20,
                    errorBuilder: (_, __, ___) => const Icon(Icons.cloud_queue, size: 20, color: Color(0xFF3ECF8E)),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Supabase Project Info',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildDetailRow('Project Ref', sup['project_ref'] ?? 'llumlzzczufzgjtvzhuc', canCopy: true),
              _buildDetailRow('REST API', sup['auth_status'] ?? 'Active'),
              _buildDetailRow('Storage Bucket', sup['storage_bucket'] ?? 'menu-images'),
              _buildDetailRow('Storage Status', sup['storage_status'] ?? 'Ready'),
              _buildDetailRow('Postgres DB', db['database_name'] ?? 'postgres'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Connection Pool & Driver
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune_rounded, size: 20, color: AppColors.brandPrimary),
                  SizedBox(width: 10),
                  Text(
                    'Engine & Pool Settings',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildDetailRow('Dialect', pool['engine'] ?? 'postgresql'),
              _buildDetailRow('DB Driver', pool['driver'] ?? 'psycopg2'),
              _buildDetailRow('Pool Size', '${pool['pool_size'] ?? 10} connections'),
              _buildDetailRow('Max Overflow', '+${pool['max_overflow'] ?? 20} burst'),
              _buildDetailRow('Pool Pre-Ping', 'Enabled (Auto-reconnect)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 12),
          const Text(
            'Could Not Fetch Health Metrics',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchHealthData,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
