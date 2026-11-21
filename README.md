# Mobile app — Fife Nearby Taxis

**One Flutter application** with two roles:

- **Passenger** — lime booking UI, map placeholder, trips, profile  
- **Driver** — online toggle, accept/reject, earnings, documents, profile  

Admin is **not** in this app (see `../admin_dashboard`).

```bash
flutter pub get
flutter run                 # Android preferred
flutter test
```

Role is chosen on the login screen. Data is mock (`lib/services/mock_repository.dart`).
Google Maps: placeholder until an API key is added.

To configure Google Maps locally, set `GOOGLE_MAPS_API_KEY` in your shell and pass it
to Flutter as a Dart define. The value is not stored in the repository:

```bash
export GOOGLE_MAPS_API_KEY="your-restricted-maps-key"
flutter run --dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY"
```

Use an appropriately restricted Maps Platform key. Never commit API keys.
