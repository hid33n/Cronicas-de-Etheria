// Top‑level imports necesarios
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")        // FlutterFire
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    } else {
        println("⚠️ key.properties no encontrado en la raíz del proyecto")
    }
}

android {
    namespace = "com.rodrigguild.guild"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.rodrigguild.guild"
        minSdk        = 23
        targetSdk     = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }

    signingConfigs {
       if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias      = keystoreProperties["keyAlias"]   as String
                keyPassword   = keystoreProperties["keyPassword"] as String
                storeFile     = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        getByName("debug") {
        }
        getByName("release") {
            isMinifyEnabled = true      // activa R8/ProGuard
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
             if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Si no, dejamos que sea debug-keystore (útil para pruebas internas)
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
  buildscript {
    repositories {
      google()
      mavenCentral()
    }
  }

  allprojects {
    repositories {
      google()
      mavenCentral()
    }
  }