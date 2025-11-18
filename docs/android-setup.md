## Android Firebase & Signing Setup

- **Package ID**: The entire Android stack now uses `com.example.iot`. The value is declared in `android/app/build.gradle.kts` (`applicationId` & `namespace`) and enforced in `android/app/src/main/AndroidManifest.xml`.
- **Google Services**: Place the Firebase config at `android/app/google-services.json`. The `com.google.gms.google-services` Gradle plugin is already applied in `android/app/build.gradle.kts` and the classpath is declared in `android/build.gradle.kts`.
- **Release signing**: `key.properties` references `android/app/upload-keystore.jks`. Ensure the file stays in that path and keep the passwords in `key.properties` up to date.
- **Debug signing**: The default Android debug keystore (`C:\Users\AMT\.android\debug.keystore`) is used automatically by Gradle/Flutter for debug builds.

### Fingerprints to register in Firebase

| Variant | SHA1 | SHA256 |
| --- | --- | --- |
| Release (`upload-keystore.jks`, alias `root`) | `43:1D:59:5C:B2:D7:E8:9B:7E:6B:4C:0E:58:87:BA:97:E7:15:DF:F8` | `83:BB:11:14:1E:63:60:6B:C5:C7:B3:5E:E3:30:34:F4:3E:EE:4E:B6:B1:72:E0:67:BB:96:94:23:EB:6F:04:78` |
| Debug (`C:\Users\AMT\.android\debug.keystore`, alias `androiddebugkey`) | `32:DA:00:C8:61:4B:6B:C8:52:33:E6:EC:03:C8:5E:C8:B0:C5:6C:2F` | `C5:F6:B6:A7:BB:6E:96:7B:D0:60:73:BF:A4:91:93:4E:6C:E1:D0:9F:82:44:4C:02:72:09:AD:65:C0:5D:A7:C3` |

### Regenerating fingerprints

```
# Release (same directory as pubspec.yaml)
keytool -list -v -alias root -keystore android/app/upload-keystore.jks -storepass 123456 -keypass 123456

# Debug (default Android Studio keystore)
keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore -storepass android -keypass android
```

Register both fingerprints for the Android app with package `com.example.iot` inside your Firebase project to enable Google sign‑in, dynamic links, and other SHA-bound services for debug and release.

