import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:auth_session/auth_session.dart';
import 'package:customer_app/main.dart';
import 'package:customer_app/src/state/cart_state.dart';

void main() {
  testWidgets('Customer app renders login screen when unauthenticated', (tester) async {
    final apiClient = ApiClient(baseUrl: 'http://localhost:8000');
    final authSession = AuthSessionManager(apiClient: apiClient);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: apiClient),
          ChangeNotifierProvider<AuthSessionManager>.value(value: authSession),
          ChangeNotifierProvider<CartState>(create: (_) => CartState()),
        ],
        child: const CustomerApp(),
      ),
    );

    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('LOG IN'), findsOneWidget);
  });
}
