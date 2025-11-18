# Android Keystore Setup - Quick Guide

## Step 1: Create Keystore

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Enter password and details when prompted.

## Step 2: Create key.properties

Create `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

## Step 3: Update build.gradle.kts

Add after plugins block:
```kotlin
val keystoreProperties = java.util.Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}
```

Add inside android block:
```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}
```

Update buildTypes:
```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

## Step 4: Get SHA Fingerprints

```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

Copy SHA-1 and SHA-256 fingerprints.

## Step 5: Add to Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Project Settings → Your Android App
3. Click "Add fingerprint"
4. Add SHA-1 and SHA-256
5. Download updated `google-services.json`
6. Replace `android/app/google-services.json`

## Step 6: Build Release

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

## Security Notes

- ⚠️ Never commit `key.properties` or `*.jks` files
- 💾 Backup your keystore securely
- 🔒 Use strong passwords

---

**Done!** Your app is now configured for release builds.

