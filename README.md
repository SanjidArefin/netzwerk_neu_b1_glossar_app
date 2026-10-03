# B1 Glossar (Android)

Offline Netzwerk neu B1 vocabulary glossary for Android. Bundles the curated
9,435-word dataset, no internet connection required.

## Download

[Download B1 Glossar for Android](https://github.com/SanjidArefin/netzwerk_neu_b1_glossar_app/releases/download/v1.2.0/B1.Glossar.Android.1.2.0.apk)

To install the Android app, open the downloaded APK. Android may ask you to
allow your browser or file manager to install apps from unknown sources.

## Development

```powershell
flutter pub get
flutter run
```

## Release APK

The release build is signed with a local Android keystore. The keystore and its
`android/key.properties` configuration are intentionally ignored by Git.

Back up `b1-glossar-android-release.jks` in a secure password manager or
encrypted storage. It is **not** stored in this repository. The current local
path is:

- `D:\coding\keys\b1-glossar-android-release.jks`

`android/key.properties` must exist locally for a signed release build and is
gitignored. It points at the keystore above and supplies the signing password.

Both are required to publish any future update that installs over an existing
B1 Glossar Android installation. Without the original keystore, an update cannot
be installed over the existing app — it would require an uninstall.

Build the release APK with:

```powershell
flutter build apk --release
```

The output is `build\app\outputs\flutter-apk\app-release.apk`.
