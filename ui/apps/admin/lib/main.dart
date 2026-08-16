import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:auth_session/auth_session.dart';
import 'package:design_system/design_system.dart';
import 'src/screens/auth/admin_login_screen.dart';
import 'src/screens/dashboard/admin_dashboard_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000');

  final apiClient = ApiClient(baseUrl: apiBaseUrl);
  final authSession = AuthSessionManager(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AuthSessionManager>.value(value: authSession),
      ],
      child: const AdminWebApp(),
    ),
  );
}

class AdminWebApp extends StatefulWidget {
  const AdminWebApp({super.key});

  @override
  State<AdminWebApp> createState() => _AdminWebAppState();
}

class _AdminWebAppState extends State<AdminWebApp> {
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
      title: 'M&S Delivery Operations Console',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: auth.isAuthenticated ? const AdminDashboardShell() : const AdminLoginScreen(),
    );
  }
}
