---
description: Build a release version of the Android App Bundle (AAB)
---
# How to Build a Release App Bundle

To build a release version of your app for the Google Play Store, you need to follow these steps.

## 1. Fix Android Environment Issues
Currently, your environment is missing the `cmdline-tools` which causes the build to fail at the symbol stripping stage.

1.  Open **Android Studio**.
2.  Go to **Settings (or Preferences)** > **Languages & Frameworks** > **Android SDK**.
3.  Select the **SDK Tools** tab.
4.  Check **Android SDK Command-line Tools (latest)**.
5.  Click **Apply** to install.
6.  Once installed, run the following in your terminal to accept licenses:
    ```bash
    flutter doctor --android-licenses
    ```

## 2. Set up Signing (Keystore)
You need a cryptographic key to sign your app.

1.  **Create a Keystore** (if you haven't already):
    Run this command in your terminal:
    ```bash
    keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
    ```
    *Keep your password and keystore file safe!*

2.  **Create `android/key.properties`**:
    Create a file named `key.properties` in the `android/` directory with the following content (replace values with yours):
    ```properties
    storePassword=<your-store-password>
    keyPassword=<your-key-password>
    keyAlias=upload
    storeFile=/Users/charles/upload-keystore.jks
    ```
    *Note: Use the absolute path to your keystore file so Gradle can find it.*

## 3. Configure `build.gradle.kts`
Update `android/app/build.gradle.kts` to use the signing configuration.

Replace the `buildTypes` block with:

```kotlin
    signingConfigs {
        create("release") {
            val keyPropertiesFile = rootProject.file("key.properties")
            if (keyPropertiesFile.exists()) {
                val properties = java.util.Properties()
                properties.load(keyPropertiesFile.inputStream())
                keyAlias = properties.getProperty("keyAlias")
                keyPassword = properties.getProperty("keyPassword")
                storeFile = file(properties.getProperty("storeFile"))
                storePassword = properties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
```

## 4. Build the App Bundle
Finally, run the build command:

```bash
flutter build appbundle
```

The output file will be located at: `build/app/outputs/bundle/release/app-release.aab`
