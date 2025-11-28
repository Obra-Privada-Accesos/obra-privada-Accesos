plugins {
    id("com.android.application")
    id("kotlin-android")
<<<<<<< HEAD
    // 👇 Plugin de Google Services para Firebase
    id("com.google.gms.google-services")
    // El plugin de Flutter SIEMPRE va al final
=======
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
>>>>>>> fae0d21e6a4cf929f087b2db595d9fa61b8c55ea
    id("dev.flutter.flutter-gradle-plugin")
}

android {
<<<<<<< HEAD
    namespace = "com.example.obraprivada"
=======
    namespace = "com.example.obra_privada_accesos"
>>>>>>> fae0d21e6a4cf929f087b2db595d9fa61b8c55ea
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
<<<<<<< HEAD
        applicationId = "com.example.obraprivada" // 👈 este mismo usaste en Firebase, ¿verdad?
=======
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.obra_privada_accesos"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
>>>>>>> fae0d21e6a4cf929f087b2db595d9fa61b8c55ea
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
<<<<<<< HEAD
            // Para no complicarnos con firma, usa debug por ahora
=======
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
>>>>>>> fae0d21e6a4cf929f087b2db595d9fa61b8c55ea
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
