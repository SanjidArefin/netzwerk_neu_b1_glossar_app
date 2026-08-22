# B1 Glossar for Android

The Android app is a fully offline Flutter version of B1 Glossar. It bundles the
same curated dataset as the Windows Electron app: 12 chapters and 9,435 entries.

## Development

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

The bundled asset at `assets/data/glossary.json` must exactly match the canonical
file at `../backend/data/glossary.json`. From the repository root, run:

```powershell
npm run sync-mobile-data
npm run validate-mobile-data
```

## Release APK

The release build is signed with a local Android keystore. The keystore and its
`android/key.properties` configuration are intentionally ignored by Git.

Back up both of these files in a secure password manager or encrypted storage:

- `D:\coding\keys\b1-glossar-android-release.jks`
- `mobile\android\key.properties`

They are required to publish any future update that installs over an existing B1
Glossar Android installation.

Build the release APK with:

```powershell
flutter build apk --release
```

The output is `build\app\outputs\flutter-apk\app-release.apk`.
