plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // FlutterFire
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flostat_application"
    compileSdk = 36 // Match your target SDK
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.flostat_application"
        minSdk = flutter.minSdkVersion      // Required for flutter_local_notifications
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }
}

dependencies {
    // Required for flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Add any other dependencies here
}

flutter {
    source = "../.."
}
