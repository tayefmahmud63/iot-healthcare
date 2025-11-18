# Android Keystore Setup and Firebase Configuration Guide

This guide will walk you through creating an Android keystore, configuring it in your Flutter project, and adding the SHA fingerprints to Firebase.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Step 1: Create a Keystore](#step-1-create-a-keystore)
3. [Step 2: Create key.properties File](#step-2-create-keyproperties-file)
4. [Step 3: Configure build.gradle.kts](#step-3-configure-buildgradlekts)
5. [Step 4: Get SHA Fingerprints](#step-4-get-sha-fingerprints)
6. [Step 5: Add SHA Fingerprints to Firebase](#step-5-add-sha-fingerprints-to-firebase)
7. [Step 6: Verify the Setup](#step-6-verify-the-setup)
8. [Troubleshooting](#troubleshooting)
9. [Security Best Practices](#security-best-practices)

---

## Prerequisites

- Java JDK installed (for `keytool` command)
- Firebase project created
- Android app registered in Firebase Console
- Flutter SDK installed

---

## Step 1: Create a Keystore

Open your terminal and navigate to your project root directory, then run:

### Windows (PowerShell):
```powershell
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### macOS/Linux:
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### What you'll be prompted for:

1. **Keystore password**: Create a strong password (save this securely!)
2. **Re-enter password**: Confirm the password
3. **First and last name**: Your name or organization name
4. **Organizational unit**: Your department (optional)
5. **Organization**: Your company name
6. **City or Locality**: Your city
7. **State or Province**: Your state/province
8. **Country code**: Two-letter country code (e.g., US, BD, IN)
9. **Confirm**: Type 'yes' to confirm
10. **Key password**: Press Enter to use the same password as keystore, or enter a different one

### Important Notes:
- The keystore file will be created at `android/app/upload-keystore.jks`
- **Keep your keystore password safe** - you'll need it for signing release builds
- The validity period is set to 10000 days (~27 years)

---

## Step 2: Create key.properties File

Create a new file at `android/key.properties` with the following content:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

### Replace the placeholders:
- `YOUR_KEYSTORE_PASSWORD`: The password you set for the keystore
- `YOUR_KEY_PASSWORD`: The password you set for the key (usually the same as keystore password)

### Example:
```properties
storePassword=MySecurePassword123!
keyPassword=MySecurePassword123!
keyAlias=upload
storeFile=upload-keystore.jks
```

### Security Note:
- The `key.properties` file is already in `.gitignore` - **never commit it to version control**
- Keep this file secure and never share it publicly

---

## Step 3: Configure build.gradle.kts

Update your `android/app/build.gradle.kts` file to use the keystore for release builds.

### Add this code at the top of the file (after the plugins block):

```kotlin
// Load keystore properties
val keystoreProperties = java.util.Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}
```

### Add the signingConfigs block inside the android block:

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

### Update the buildTypes block:

```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = false
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }
}
```

### Complete Example:

Here's how your `build.gradle.kts` should look:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Load keystore properties
val keystoreProperties = java.util.Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.bmtechlab.iot"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.bmtechlab.iotproject"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
```

---

## Step 4: Get SHA Fingerprints

You need to extract the SHA-1 and SHA-256 fingerprints from your keystore to add them to Firebase.

### Get All Certificate Information:

#### Windows (PowerShell):
```powershell
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

#### macOS/Linux:
```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

You'll be prompted for the keystore password. After entering it, you'll see output like:

```
Certificate fingerprints:
     SHA1: AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE
     SHA256: 11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:11:22
```

### Extract Only SHA-1:

#### Windows (PowerShell):
```powershell
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload | Select-String "SHA1"
```

#### macOS/Linux:
```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload | grep SHA1
```

### Extract Only SHA-256:

#### Windows (PowerShell):
```powershell
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload | Select-String "SHA256"
```

#### macOS/Linux:
```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload | grep SHA256
```

### Copy the fingerprints:
- Copy the SHA-1 fingerprint (the long string of hex values separated by colons)
- Copy the SHA-256 fingerprint (the longer string of hex values separated by colons)
- You'll need both for Firebase

---

## Step 5: Add SHA Fingerprints to Firebase

1. **Go to Firebase Console**
   - Navigate to [https://console.firebase.google.com/](https://console.firebase.google.com/)
   - Select your project

2. **Open Project Settings**
   - Click the gear icon (⚙️) next to "Project Overview"
   - Select "Project settings"

3. **Navigate to Your Android App**
   - Scroll down to the "Your apps" section
   - Find your Android app (package name: `com.bmtechlab.iotproject`)

4. **Add SHA Fingerprints**
   - Click "Add fingerprint" button
   - Add your **SHA-1** fingerprint
   - Click "Add fingerprint" again
   - Add your **SHA-256** fingerprint

5. **Download Updated google-services.json**
   - After adding fingerprints, download the updated `google-services.json` file
   - Replace the existing file at `android/app/google-services.json`

### Why This is Important:
- Firebase Authentication requires SHA fingerprints for Google Sign-In
- Firebase Dynamic Links need SHA fingerprints
- Other Firebase services may require them for security

---

## Step 6: Verify the Setup

### Build a Release APK:
```bash
flutter build apk --release
```

### Build an App Bundle (for Google Play):
```bash
flutter build appbundle --release
```

### Check the Build Output:
- The build should complete without errors
- The APK/AAB will be signed with your keystore
- Location: `build/app/outputs/flutter-apk/app-release.apk` or `build/app/outputs/bundle/release/app-release.aab`

### Verify Signing:
You can verify that your APK is signed correctly:

#### Windows (PowerShell):
```powershell
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

#### macOS/Linux:
```bash
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

---

## Troubleshooting

### Issue: "key.properties file not found"
**Solution**: Make sure the `key.properties` file is in the `android/` directory (not `android/app/`)

### Issue: "Keystore password incorrect"
**Solution**: 
- Double-check the password in `key.properties`
- Make sure there are no extra spaces or special characters
- Try regenerating the keystore if needed

### Issue: "Build fails with signing config error"
**Solution**:
- Verify that `key.properties` exists and has correct values
- Check that the keystore file path in `key.properties` is correct
- Ensure the alias name matches (`upload`)

### Issue: "Firebase services not working after adding SHA"
**Solution**:
- Make sure you downloaded the updated `google-services.json` after adding SHA fingerprints
- Wait a few minutes for Firebase to propagate changes
- Clear app data and reinstall the app

### Issue: "Cannot find keytool command"
**Solution**:
- Make sure Java JDK is installed
- Add Java bin directory to your PATH environment variable
- On Windows, it's usually: `C:\Program Files\Java\jdk-XX\bin`
- On macOS with Homebrew: `brew install openjdk`

---

## Security Best Practices

### 1. **Never Commit Sensitive Files**
The following files are already in `.gitignore`:
- `key.properties`
- `*.keystore`
- `*.jks`

**Never commit these files to version control!**

### 2. **Backup Your Keystore**
- Store a backup of `upload-keystore.jks` in a secure location (encrypted storage, password manager, etc.)
- If you lose the keystore, you **cannot** update your app on Google Play Store
- Consider using multiple secure backup locations

### 3. **Use Strong Passwords**
- Use a strong, unique password for your keystore
- Consider using a password manager to store it securely
- Document the password in a secure location (not in code!)

### 4. **Limit Access**
- Only share keystore credentials with trusted team members
- Use environment variables or secure secret management for CI/CD pipelines

### 5. **Rotate if Compromised**
- If your keystore is ever compromised, you'll need to create a new one
- Note: This may require creating a new app listing on Google Play if you can't update the existing one

### 6. **CI/CD Considerations**
For automated builds, consider:
- Using environment variables instead of `key.properties`
- Using secure secret management (GitHub Secrets, GitLab CI Variables, etc.)
- Never hardcode passwords in build scripts

---

## Additional Resources

- [Flutter Android Signing Documentation](https://docs.flutter.dev/deployment/android#signing-the-app)
- [Android App Signing Guide](https://developer.android.com/studio/publish/app-signing)
- [Firebase Console](https://console.firebase.google.com/)
- [Google Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)

---

## Quick Reference Commands

### Create Keystore:
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Get SHA Fingerprints:
```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

### Build Release APK:
```bash
flutter build apk --release
```

### Build Release App Bundle:
```bash
flutter build appbundle --release
```

### Verify APK Signature:
```bash
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

---

## Summary Checklist

- [ ] Created keystore file (`upload-keystore.jks`)
- [ ] Created `key.properties` file with correct credentials
- [ ] Updated `build.gradle.kts` with signing configuration
- [ ] Extracted SHA-1 and SHA-256 fingerprints
- [ ] Added SHA fingerprints to Firebase Console
- [ ] Downloaded updated `google-services.json`
- [ ] Successfully built release APK/AAB
- [ ] Verified APK signature
- [ ] Backed up keystore securely
- [ ] Tested Firebase services (Authentication, etc.)

---

**Last Updated**: 2024
**Project**: IoT Healthcare Application
**Package Name**: com.bmtechlab.iotproject

