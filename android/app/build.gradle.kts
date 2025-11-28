plugins {
    id("com.android.application")
    id("kotlin-android")
    // 👇 Plugin de Google Services para Firebase
    id("com.google.gms.google-services")
    // El plugin de Flutter SIEMPRE va al final
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.obraprivada"
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
        applicationId = "com.example.obraprivada" // 👈 este mismo usaste en Firebase, ¿verdad?
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Para no complicarnos con firma, usa debug por ahora
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
