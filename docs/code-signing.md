# Code Signing Guide

**Car Post All**

This document covers how to set up code signing for release builds on Android and iOS. Both platforms require signed builds before you can publish to their respective app stores.

---

## Android: Signing an App Bundle

### 1. Create a Keystore

Generate a new keystore file using `keytool` (bundled with Java):

```bash
keytool -genkey -v \
  -keystore ~/car-post-all-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias car-post-all
```

You will be prompted for:

- **Keystore password** -- choose a strong password and store it securely (e.g., in a password manager).
- **Key password** -- can be the same as the keystore password.
- **Distinguished name fields** -- your name, organization, city, state, country.

Store the `.jks` file securely. **Never commit it to version control.** Losing this file means you cannot update your app on the Play Store.

### 2. Create `key.properties`

Create a file at `mobile/android/key.properties` with the following content:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=car-post-all
storeFile=/path/to/car-post-all-release.jks
```

Add this file to `.gitignore` -- it must never be committed:

```gitignore
# mobile/android/.gitignore
key.properties
```

### 3. Configure `build.gradle.kts`

Edit `mobile/android/app/build.gradle.kts` to load the keystore and sign release builds:

```kotlin
import java.util.Properties
import java.io.FileInputStream

// Load key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### 4. Build a Signed App Bundle

```bash
cd mobile
flutter build appbundle --release
```

The signed `.aab` file will be at:

```
mobile/build/app/outputs/bundle/release/app-release.aab
```

Upload this file to the Google Play Console.

### 5. CI/CD Signing

For GitHub Actions, store the keystore as a base64-encoded secret:

```bash
# Encode the keystore
base64 -i ~/car-post-all-release.jks | pbcopy
```

Add these GitHub Actions secrets:

| Secret | Value |
|--------|-------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded `.jks` file |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_KEY_ALIAS` | `car-post-all` |

In your workflow, decode the keystore and create `key.properties` before building:

```yaml
- name: Decode keystore
  run: |
    echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore.jks
    echo "storePassword=${{ secrets.ANDROID_KEYSTORE_PASSWORD }}" > android/key.properties
    echo "keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}" >> android/key.properties
    echo "keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}" >> android/key.properties
    echo "storeFile=keystore.jks" >> android/key.properties
```

---

## iOS: Certificates and Provisioning Profiles

iOS code signing requires an Apple Developer account ($99/year) and involves certificates, identifiers, and provisioning profiles.

### 1. Apple Developer Account Setup

1. Enroll at [developer.apple.com](https://developer.apple.com/programs/).
2. In the Apple Developer portal, register a new **App ID** with the bundle identifier matching your app (e.g., `com.carpostall.app`).
3. Confirm the bundle identifier in `mobile/ios/Runner.xcodeproj` matches.

### 2. Certificates

You need two types of certificates:

| Certificate | Purpose |
|-------------|---------|
| **Apple Development** | Sign builds for testing on physical devices |
| **Apple Distribution** | Sign builds for App Store / TestFlight |

To create a distribution certificate:

1. Open **Xcode** > **Settings** > **Accounts** > select your Apple ID > **Manage Certificates**.
2. Click **+** and select **Apple Distribution**.
3. Xcode generates a certificate signing request, submits it to Apple, and installs the certificate in your Keychain.

Alternatively, create certificates manually in the Apple Developer portal under **Certificates, Identifiers & Profiles**.

### 3. Provisioning Profiles

Provisioning profiles link your app ID, certificate, and (for development) specific device UDIDs.

| Profile Type | Purpose |
|-------------|---------|
| **iOS App Development** | Run on registered test devices |
| **App Store Connect** | Submit to App Store / TestFlight |

Create profiles in the Apple Developer portal:

1. Go to **Profiles** > **+**.
2. Select the profile type.
3. Choose your App ID and certificate.
4. Download and double-click to install (or let Xcode manage it automatically).

### 4. Xcode Signing Configuration

The simplest approach is automatic signing:

1. Open `mobile/ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** target > **Signing & Capabilities**.
3. Check **Automatically manage signing**.
4. Select your **Team** (your Apple Developer account).
5. Xcode will create and manage provisioning profiles for you.

For manual signing (CI/CD):

1. Uncheck **Automatically manage signing**.
2. Under **Release**, select your App Store distribution profile.
3. Under **Debug**, select your development profile.

### 5. Build for Release

```bash
cd mobile
flutter build ipa --release
```

The output `.ipa` file will be at:

```
mobile/build/ios/ipa/car_post_all.ipa
```

Upload to App Store Connect using:

- **Xcode** > **Distribute App** (from the Archive), or
- **Transporter** app (drag and drop the `.ipa`), or
- `xcrun altool --upload-app` from the command line.

### 6. CI/CD Signing (GitHub Actions)

For automated builds, you need to install the certificate and provisioning profile on the runner:

1. Export your distribution certificate as a `.p12` file from Keychain Access.
2. Base64-encode the `.p12` and provisioning profile.
3. Store them as GitHub Actions secrets.

Add these secrets:

| Secret | Value |
|--------|-------|
| `IOS_CERTIFICATE_P12_BASE64` | Base64-encoded `.p12` file |
| `IOS_CERTIFICATE_PASSWORD` | Password for the `.p12` file |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64-encoded `.mobileprovision` |

In your workflow:

```yaml
- name: Install certificate and profile
  env:
    CERTIFICATE: ${{ secrets.IOS_CERTIFICATE_P12_BASE64 }}
    CERT_PASSWORD: ${{ secrets.IOS_CERTIFICATE_PASSWORD }}
    PROFILE: ${{ secrets.IOS_PROVISIONING_PROFILE_BASE64 }}
  run: |
    # Create temporary keychain
    security create-keychain -p "" build.keychain
    security default-keychain -s build.keychain
    security unlock-keychain -p "" build.keychain

    # Import certificate
    echo "$CERTIFICATE" | base64 -d > cert.p12
    security import cert.p12 -k build.keychain -P "$CERT_PASSWORD" -T /usr/bin/codesign
    security set-key-partition-list -S apple-tool:,apple: -s -k "" build.keychain

    # Install provisioning profile
    mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
    echo "$PROFILE" | base64 -d > ~/Library/MobileDevice/Provisioning\ Profiles/build.mobileprovision
```

---

## Security Best Practices

- **Never commit** keystores, `.p12` files, `key.properties`, or provisioning profiles to version control.
- **Use a password manager** to store all signing credentials.
- **Back up your Android keystore** -- if you lose it, you cannot push updates to your existing Play Store listing.
- **Rotate certificates** before they expire (Apple certificates expire after 1 year by default).
- **Use GitHub Actions secrets** (or your CI provider's equivalent) for all sensitive signing material.
- **Consider Fastlane Match** for iOS if you have multiple developers -- it stores encrypted certificates in a private Git repo.

---

## References

- [Flutter: Build and release an Android app](https://docs.flutter.dev/deployment/android)
- [Flutter: Build and release an iOS app](https://docs.flutter.dev/deployment/ios)
- [Android: Sign your app](https://developer.android.com/studio/publish/app-signing)
- [Apple: Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Fastlane Match](https://docs.fastlane.tools/actions/match/)
