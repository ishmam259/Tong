plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google services plugin removed - using local authentication
    // id("com.google.gms.google-services")
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(24)
    }
}

android {
    namespace = "com.example.tong"
    compileSdk = 35  // Updated to meet shared_preferences_android requirement
    ndkVersion = "27.0.12077973"  // Updated to meet plugin requirements

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.tong"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23  // Increased for Bluetooth LE support
        targetSdk = 35  // Updated to match compileSdk
        versionCode = 1
        versionName = "1.0.0"
        
        // Multidex removed with Firebase dependencies
        // multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase dependencies removed - using local authentication
    // implementation("androidx.multidex:multidex:2.0.1")
    // implementation(platform("com.google.firebase:firebase-bom:34.0.0"))
}
