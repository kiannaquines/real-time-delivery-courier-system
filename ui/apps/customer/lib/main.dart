import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:auth_session/auth_session.dart';
import 'package:design_system/design_system.dart';
import 'src/state/cart_state.dart';
import 'src/screens/auth/login_screen.dart';
import 'src/screens/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // In production, configure through environment variables
  const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000');

  final apiClient = ApiClient(baseUrl: apiBaseUrl);
  final authSession = AuthSessionManager(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AuthSessionManager>.value(value: authSession),
        ChangeNotifierProvider<CartState>(create: (_) => CartState()),
      ],
      child: const CustomerApp(),
    ),
  );
}

class CustomerApp extends StatefulWidget {
  const CustomerApp({super.key});

  @override
  State<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends State<CustomerApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthSessionManager>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthSessionManager>();

    return MaterialApp(
      title: 'M&S Delivery Customer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: auth.isAuthenticated ? const CustomerHomeScreen() : const CustomerLoginScreen(),
    );
  }
}
