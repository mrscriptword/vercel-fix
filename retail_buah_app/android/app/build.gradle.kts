plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin (WAJIB terakhir)
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.retail_buah_app"
    compileSdk = flutter.compileSdkVersion

    // ✅ FIX NDK (WAJIB)
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.retail_buah_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        // ✅ FIX KOTLIN DSL FLUTTER
        versionCode = flutter.versionCode()
        versionName = flutter.versionName()
    }

    buildTypes {
        release {
            // sementara pakai debug signing (AMAN UNTUK BUILD)
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
