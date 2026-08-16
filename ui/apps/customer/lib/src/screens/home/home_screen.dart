import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:domain_models/domain_models.dart';
import 'package:design_system/design_system.dart';
import 'package:auth_session/auth_session.dart';
import '../store/store_menu_screen.dart';
import '../cart/cart_screen.dart';
import '../history/order_history_screen.dart';
import '../profile/profile_screen.dart';
import '../../state/cart_state.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentTab = 0;
  List<Store> _stores = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _quickCategories = const [
    {'name': 'All', 'icon': Icons.restaurant, 'price': ''},
    {'name': 'Burger', 'icon': Icons.lunch_dining, 'price': '₱50'},
    {'name': 'Chicken', 'icon': Icons.kebab_dining, 'price': '₱120'},
    {'name': 'Pizza', 'icon': Icons.local_pizza, 'price': '₱180'},
    {'name': 'Milk Tea', 'icon': Icons.local_cafe, 'price': '₱85'},
    {'name': 'Bakery', 'icon': Icons.bakery_dining, 'price': '₱60'},
  ];

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiClient>();
      final stores = await api.getStores();
      setState(() => _stores = stores);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();

    final screens = [
      _buildHomeDashboard(cart),
      const OrderHistoryScreen(),
      const CartScreen(),
      const CustomerProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: screens[_currentTab],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (idx) => setState(() => _currentTab = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.brandPrimary),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppColors.brandPrimary),
            label: 'My Orders',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cart.itemCount > 0,
              label: Text('${cart.itemCount}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cart.itemCount > 0,
              label: Text('${cart.itemCount}'),
              child: const Icon(Icons.shopping_bag, color: AppColors.brandPrimary),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.brandPrimary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeDashboard(CartState cart) {
    final auth = context.watch<AuthSessionManager>();
    final userName = auth.currentUser?.fullName.split(' ').first ?? 'Alice';

    final filteredStores = _stores.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (s.description ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadStores,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Deliver To & Cart Header (Matches Page 56 of thesis)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DELIVER TO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandPrimary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: const [
                      Text(
                        'Purok Miracle, Kabacan',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textPrimary),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _currentTab = 2),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Badge(
                    isLabelVisible: cart.itemCount > 0,
                    label: Text('${cart.itemCount}'),
                    backgroundColor: AppColors.brandPrimary,
                    child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Greeting
          Text(
            'Hey $userName, Good Day!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),

          // Search Bar
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search dishes, restaurants in Kabacan...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 22),

          // Categories Header & Horizontal List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('All Categories', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text('See All >', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brandPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (ctx, idx) {
                final cat = _quickCategories[idx];
                final isSelected = _selectedCategory == cat['name'];
                return InkWell(
                  onTap: () => setState(() => _selectedCategory = cat['name'] as String),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 78,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brandPrimary : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.brandPrimary : AppColors.border,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.brandPrimary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          cat['icon'] as IconData,
                          size: 26,
                          color: isSelected ? Colors.white : AppColors.brandPrimary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat['name'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((cat['price'] as String).isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            cat['price'] as String,
                            style: TextStyle(
                              fontSize: 9,
                              color: isSelected ? Colors.white70 : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Open Restaurants Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Open Restaurants in Kabacan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text('See All >', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brandPrimary)),
            ],
          ),
          const SizedBox(height: 12),

          // Store Cards
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.brandPrimary)),
              ),
            )
          else if (_error != null)
            EmptyStateView(
              icon: Icons.error_outline,
              title: 'Failed to load restaurants',
              description: _error!,
              actionText: 'Retry',
              onAction: _loadStores,
            )
          else if (filteredStores.isEmpty)
            const EmptyStateView(
              icon: Icons.storefront,
              title: 'No Restaurants Found',
              description: 'Try adjusting your search query.',
            )
          else
            ...filteredStores.map((store) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => StoreMenuScreen(store: store),
                      ));
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Restaurant Cover Header
                        Container(
                          height: 130,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.brandSecondary,
                                AppColors.brandPrimary.withOpacity(0.85),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(Icons.restaurant, size: 48, color: Colors.white.withOpacity(0.3)),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.star, size: 14, color: AppColors.warning),
                                      SizedBox(width: 4),
                                      Text('4.8', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Restaurant Details
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              ),
                              if (store.description != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  store.description!,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: const [
                                  Icon(Icons.delivery_dining, size: 16, color: AppColors.brandPrimary),
                                  SizedBox(width: 4),
                                  Text('₱49 Base Fee', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  SizedBox(width: 14),
                                  Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                                  SizedBox(width: 4),
                                  Text('15-25 min', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
