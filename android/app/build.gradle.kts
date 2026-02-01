kotlin
// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Tu plugin de Google Services, sin cambios
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.hefestocs"
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
        // Tu Application ID, sin cambios
        applicationId = "com.example.hefestocs"
        minSdk = flutter.minSdkVersion

        // ▼▼▼ CORRECCIÓN CLAVE Y ÚNICA APLICADA AQUÍ ▼▼▼
        // Se fija la targetSdk a 32 para asegurar la compatibilidad con el
        // almacenamiento heredado (requestLegacyExternalStorage) que tu app necesita.
        targetSdk = 32

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Tu configuración de multidex, sin cambios
        multiDexEnabled = true
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

// Tus dependencias, sin cambios
dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
}
