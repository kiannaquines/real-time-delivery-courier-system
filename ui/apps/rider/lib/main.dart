import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:auth_session/auth_session.dart';
import 'package:design_system/design_system.dart';
import 'src/state/location_engine.dart';
import 'src/screens/auth/rider_login_screen.dart';
import 'src/screens/dashboard/rider_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000');

  final apiClient = ApiClient(baseUrl: apiBaseUrl);
  final authSession = AuthSessionManager(apiClient: apiClient);
  final locationEngine = LocationEngine(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AuthSessionManager>.value(value: authSession),
        ChangeNotifierProvider<LocationEngine>.value(value: locationEngine),
      ],
      child: const RiderApp(),
    ),
  );
}

class RiderApp extends StatefulWidget {
  const RiderApp({super.key});

  @override
  State<RiderApp> createState() => _RiderAppState();
}

class _RiderAppState extends State<RiderApp> {
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
      title: 'M&S Rider Fleet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: auth.isAuthenticated ? const RiderDashboardScreen() : const RiderLoginScreen(),
    );
  }
}
