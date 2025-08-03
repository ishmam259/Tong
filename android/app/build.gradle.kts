

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Removed toolchain block; use compileOptions for Java version

android {
    namespace = "com.example.tong"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Still using VERSION_17 because JavaVersion enum doesn't support 24 yet
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17" // or "24", but may cause errors if unsupported
    }

    defaultConfig {
        applicationId = "com.example.tong"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase removed
}
