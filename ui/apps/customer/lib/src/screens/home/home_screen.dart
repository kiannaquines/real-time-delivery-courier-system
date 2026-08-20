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
import '../profile/saved_addresses_screen.dart';
import '../../state/cart_state.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentTab = 0;
  List<Store> _stores = [];
  Address? _currentAddress;
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _quickCategories = const [
    {'name': 'All', 'icon': Icons.restaurant_rounded, 'price': ''},
    {'name': 'Burger', 'icon': Icons.lunch_dining_rounded, 'price': '₱50'},
    {'name': 'Chicken', 'icon': Icons.kebab_dining_rounded, 'price': '₱120'},
    {'name': 'Pizza', 'icon': Icons.local_pizza_rounded, 'price': '₱180'},
    {'name': 'Milk Tea', 'icon': Icons.local_cafe_rounded, 'price': '₱85'},
    {'name': 'Bakery', 'icon': Icons.bakery_dining_rounded, 'price': '₱60'},
  ];

  @override
  void initState() {
    super.initState();
    _loadStores();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    try {
      final api = context.read<ApiClient>();
      final addresses = await api.getAddresses();
      if (mounted && addresses.isNotEmpty) {
        setState(() {
          _currentAddress = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
        });
      }
    } catch (_) {}
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
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.brandPrimary),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.brandPrimary),
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
              child: const Icon(Icons.shopping_bag_rounded, color: AppColors.brandPrimary),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.brandPrimary),
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
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        children: [
          // Deliver To Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final selected = await Navigator.of(context).push<Address>(
                      MaterialPageRoute(builder: (_) => const SavedAddressesScreen(isSelecting: true)),
                    );
                    if (selected != null && mounted) {
                      setState(() => _currentAddress = selected);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DELIVER TO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.brandPrimary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _currentAddress != null ? '${_currentAddress!.label} (${_currentAddress!.addressLine})' : 'Purok Miracle, Poblacion, Kabacan',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textPrimary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => setState(() => _currentTab = 2),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.premiumShadow,
                  ),
                  child: Badge(
                    isLabelVisible: cart.itemCount > 0,
                    label: Text('${cart.itemCount}'),
                    backgroundColor: AppColors.brandPrimary,
                    child: const Icon(Icons.shopping_bag_outlined, color: AppColors.textPrimary, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Greeting
          Text(
            'Hey $userName, what are you craving today?',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),

          // Search Bar with Light Elevation
          Container(
            decoration: BoxDecoration(
              boxShadow: AppColors.premiumShadow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search restaurants, dishes, snacks...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Categories Header & Horizontal List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(
                child: Text('Food Categories', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              SizedBox(width: 8),
              Text('See All >', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.brandPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (ctx, idx) {
                final cat = _quickCategories[idx];
                final isSelected = _selectedCategory == cat['name'];
                return InkWell(
                  onTap: () => setState(() => _selectedCategory = cat['name'] as String),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brandPrimary : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.brandPrimary : AppColors.border,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.brandPrimary.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : AppColors.premiumShadow,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          cat['icon'] as IconData,
                          size: 24,
                          color: isSelected ? Colors.white : AppColors.brandPrimary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat['name'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
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
                              fontWeight: FontWeight.w700,
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

          // Open Restaurants Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(
                child: Text('Restaurants in Kabacan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              SizedBox(width: 8),
              Text('See All >', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.brandPrimary)),
            ],
          ),
          const SizedBox(height: 14),

          // Restaurant Cards
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(36),
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
              icon: Icons.storefront_rounded,
              title: 'No Restaurants Found',
              description: 'Try adjusting your search query.',
            )
          else
            ...filteredStores.map((store) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
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
                        // Cover Graphic
                        Container(
                          height: 135,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(Icons.restaurant_rounded, size: 52, color: AppColors.brandPrimary.withOpacity(0.2)),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: AppColors.premiumShadow,
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.star_rounded, size: 15, color: Color(0xFFF59E0B)),
                                      SizedBox(width: 4),
                                      Text('4.8', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('20-30 min', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Store Info Content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      store.name,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                                ],
                              ),
                              if (store.description != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  store.description!,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      store.address,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandPrimaryLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('₱49 Delivery', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.brandPrimary)),
                                  ),
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
