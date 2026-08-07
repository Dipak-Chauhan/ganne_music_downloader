# Ganne

Ganne is a Flutter application for searching authorized Qobuz catalog content,
downloading available audio locally, tagging files, and playing downloaded
tracks from its local library.

## Requirements

- Flutter SDK compatible with Dart `^3.11.4`
- Authorized Qobuz application credentials and user token
- Android device or emulator for the primary supported download flow

The login screen is prefilled with a default Qobuz application ID and secret.
These values are embedded in distributed builds and can be extracted; they are
not private credentials. Replace them with credentials issued for an application
you are authorized to use when required. A user token is never bundled and must
still be entered at login.

## Storage And Downloads

On Android, downloads can be published through MediaStore into the shared
`Music/Ganne` or `Download/Ganne` directory, or into a custom folder selected
through Android's folder picker. Custom downloads use the selected folder
directly by default; Settings can instead create and use a dedicated `Ganne`
subdirectory. Ganne retains scoped access to the current and previously selected
custom folders so it can open and remove files it created during library cleanup;
it does not request broad all-files access. Reset removes tracked downloads and
prunes empty app subdirectories without deleting untracked files from a custom
folder. Desktop builds can also select a custom output directory. The separate
flat-download setting controls whether tracks use `Artist/Album` subfolders
inside the selected download root.

Downloads run while the Flutter process remains active. Ganne does not include
a foreground service or a background worker, so Android may pause or stop
downloads when the app is backgrounded or terminated. Interrupted download
records are returned to the queue the next time the app starts.

Album ZIP mode is configured in Settings. A ZIP is created only when every
album track downloads successfully; partial archives are discarded.

Use the app only for content and download rights authorized by Qobuz and the
applicable account, subscription, and regional terms.

## Development

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

## Android Release Signing

Release builds never use the debug signing key. To sign a release locally,
create the ignored `android/key.properties` file with your own keystore values:

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=../release.jks
```

Keep the keystore and `key.properties` private. CI should provide equivalent
values through its secure build environment.
