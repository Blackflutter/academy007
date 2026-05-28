plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.academy007"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    defaultConfig {
        applicationId = "com.example.academy007"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        // CORRIGIDO: Adicionado 'is' no início e o sinal '='
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
<<<<<<< HEAD
        jvmTarget = "17"
=======
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.academy007"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        
        // CORRIGIDO: Adicionado o sinal '='
        multiDexEnabled = true
        
        versionName = flutter.versionName
>>>>>>> 4215483e80cab869c7e983f3044f4dbeb66ca726
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
<<<<<<< HEAD
=======
    // CORRIGIDO: Sintaxe correta com parênteses e aspas duplas para Kotlin
>>>>>>> 4215483e80cab869c7e983f3044f4dbeb66ca726
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
