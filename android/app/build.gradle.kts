// android/app/build.gradle.kts
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---- Keystore (Kotlin DSL style) ----
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { fis ->
        keystoreProperties.load(fis)
    }
}

android {
    namespace = "com.daily.mantra"
    // Google Play requires apps to target API 36 (Android 16).
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.daily.mantra"
        // Android 5.0+ (API 21), as in 1.0.0: every plugin supports it. Re-check
        // before adding Firebase (firebase_core 5 needs API 24).
        minSdk = maxOf(21, flutter.minSdkVersion)
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"] as String?
            if (!storeFilePath.isNullOrBlank()) {
                storeFile = file(storeFilePath)
            }
            keyAlias = (keystoreProperties["keyAlias"] ?: "") as String
            keyPassword = (keystoreProperties["keyPassword"] ?: "") as String
            storePassword = (keystoreProperties["storePassword"] ?: "") as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            isDebuggable = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        // Optionally sign debug with release key:
        // debug { signingConfig = signingConfigs.getByName("release") }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions { jvmTarget = "17" }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // implementation("com.google.android.gms:play-services-ads:23.3.0")
}
