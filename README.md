# B1 Glossar

An offline Netzwerk neu B1 vocabulary glossary for Windows and Android. Both
apps bundle the curated 9,435-word dataset and need no internet connection.

## Download


[Download B1 Glossar for Android](https://github.com/SanjidArefin/netzwerk_neu_b1_glossar_soft/releases/download/v1.2.0/B1.Glossar.Android.1.2.0.apk)

To install the Android app, open the downloaded APK. Android may ask you to
allow your browser or file manager to install apps from unknown sources.

## Windows Development

```powershell
npm install
npm start
```

The Electron app loads its curated vocabulary from `backend/data/glossary.json`.
It opens in dark mode by default and remembers a user's light/dark preference.

## Android Development

The Flutter app is in `mobile/`. It has its own [setup and release notes](mobile/README.md).

```powershell
cd mobile
flutter pub get
flutter run
```

## Data Checks

`backend/data/glossary.json` is the canonical dataset. Sync it before an Android
release, then validate that the bundled Flutter asset is byte-for-byte identical.

```powershell
npm run sync-mobile-data
npm run validate-data
npm run validate-mobile-data
```

## Windows Installer

```powershell
npm run check
npm test
npm run test:electron
npm run dist
```

The installer is created in `release/` with Start Menu, desktop shortcut, and
uninstall support.
