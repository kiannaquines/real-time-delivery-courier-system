import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:auth_session/auth_session.dart';
import 'package:rider_app/main.dart';
import 'package:rider_app/src/state/location_engine.dart';

void main() {
  testWidgets('Rider app renders login screen when unauthenticated', (tester) async {
    final apiClient = ApiClient(baseUrl: 'http://localhost:8000');
    final authSession = AuthSessionManager(apiClient: apiClient);
    final locationEngine = LocationEngine(apiClient: apiClient);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: apiClient),
          ChangeNotifierProvider<AuthSessionManager>.value(value: authSession),
          ChangeNotifierProvider<LocationEngine>.value(value: locationEngine),
        ],
        child: const RiderApp(),
      ),
    );

    expect(find.text('Rider Login'), findsOneWidget);
    expect(find.text('LOG IN'), findsOneWidget);
  });
}
