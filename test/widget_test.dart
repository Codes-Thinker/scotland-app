import 'package:flutter_test/flutter_test.dart';
import 'package:fife_nearby_taxis/core/network/realtime_client.dart';
import 'package:fife_nearby_taxis/main.dart';
import 'package:fife_nearby_taxis/services/app_state.dart';
import 'package:fife_nearby_taxis/viewmodels/alerts_view_model.dart';
import 'package:fife_nearby_taxis/viewmodels/auth_view_model.dart';
import 'package:fife_nearby_taxis/viewmodels/chat_view_model.dart';
import 'package:fife_nearby_taxis/viewmodels/earnings_view_model.dart';
import 'package:fife_nearby_taxis/viewmodels/ride_view_model.dart';

void main() {
  testWidgets('App boots with splash branding', (tester) async {
    final auth = AuthViewModel();
    final state = AppState();
    final realtime = RealtimeClient(auth.repository.client);
    final chat = ChatViewModel(auth: auth, appState: state, realtime: realtime);
    final alerts = AlertsViewModel(auth: auth, appState: state, realtime: realtime);
    final earnings = EarningsViewModel(auth: auth, appState: state);
    final rides = RideViewModel(
      auth: auth,
      appState: state,
      realtime: realtime,
      chat: chat,
    );
    await tester.pumpWidget(
      ScotlandApp(
        auth: auth,
        appState: state,
        rides: rides,
        chat: chat,
        alerts: alerts,
        earnings: earnings,
        realtime: realtime,
      ),
    );
    await tester.pump();

    expect(find.text('Scotland'), findsOneWidget);
  });
}
