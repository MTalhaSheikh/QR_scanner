import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load android/key.properties (sits one level up from this file, at the
// root of the android/ Gradle project — NOT inside android/app/).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.alphasoftechs.qrcodescanner"
    // 37: required by permission_handler_android. AGP 9.2.x supports up to API 37.
    compileSdk = 37
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        applicationId = "com.alphasoftechs.qrcodescanner"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // Real release signing now — this is what lets Play Store
            // accept the upload and is what makes `flutter build appbundle
            // --release` produce a properly signed, publishable .aab.
            signingConfig = signingConfigs.getByName("release")

            // TEMPORARY test: R8 shrinking is off to check whether it causes the
            // startup crash in release. Once the app runs fine, we add proper
            // keep rules and turn these back on.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

// Replaces the old `kotlinOptions { jvmTarget = ... }` block (removed in newer Kotlin/AGP).
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
    }
}

flutter {
    source = "../.."
}