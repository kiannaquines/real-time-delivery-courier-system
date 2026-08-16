import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:auth_session/auth_session.dart';
import 'package:admin_web_app/main.dart';

void main() {
  testWidgets('Admin web app renders login screen when unauthenticated', (tester) async {
    final apiClient = ApiClient(baseUrl: 'http://localhost:8000');
    final authSession = AuthSessionManager(apiClient: apiClient);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: apiClient),
          ChangeNotifierProvider<AuthSessionManager>.value(value: authSession),
        ],
        child: const AdminWebApp(),
      ),
    );

    expect(find.text('M&S Command Center'), findsOneWidget);
    expect(find.text('Authenticate Console'), findsOneWidget);
  });
}
