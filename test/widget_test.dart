import 'package:flutter_test/flutter_test.dart';
import 'package:fife_nearby_taxis/main.dart';
import 'package:fife_nearby_taxis/services/app_state.dart';

void main() {
  testWidgets('App boots with splash branding', (tester) async {
    final state = AppState();
    await tester.pumpWidget(FifeNearbyTaxisApp(state: state));
    await tester.pump();

    expect(find.text('Scotland'), findsOneWidget);
  });
}
