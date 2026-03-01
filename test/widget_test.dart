import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/providers/challenge_provider.dart';
import 'package:flutter_application_1/providers/mochi_point_account_provider.dart';
import 'package:flutter_application_1/providers/mochi_point_provider.dart';
import 'package:flutter_application_1/providers/eaty_provider.dart';
import 'package:flutter_application_1/providers/cart_item_provider.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app with providers and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ChallengeProvider()),
          ChangeNotifierProvider(create: (context) => MochiPointAccountProvider()),
          ChangeNotifierProvider(create: (context) => MochiPointProvider()),
          ChangeNotifierProvider(create: (context) => EatyProvider()),
          ChangeNotifierProvider(create: (context) => CartItemProvider()),
        ],
        child: const MochiPointsApp(),
      ),
    );

    // Verify that the app title is displayed.
    expect(find.text('Mochi Points'), findsWidgets);
  });
}
