import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun loadSigningProperties(fileName: String): Properties {
    val properties = Properties()
    val propertiesFile = rootProject.file(fileName)

    if (propertiesFile.exists()) {
        FileInputStream(propertiesFile).use(properties::load)
    }

    return properties
}

fun Properties.hasSigningCredentials(): Boolean {
    return listOf("storeFile", "storePassword", "keyAlias", "keyPassword").all {
        !getProperty(it).isNullOrBlank()
    }
}

val debugSigningProperties = loadSigningProperties("debug-key.properties")
val releaseSigningProperties = loadSigningProperties("release-key.properties")
val hasDebugSigning = debugSigningProperties.hasSigningCredentials()
val hasReleaseSigning = releaseSigningProperties.hasSigningCredentials()

android {
    namespace = "com.example.smenergy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.smenergy"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        getByName("debug") {
            if (hasDebugSigning) {
                storeFile = rootProject.file(debugSigningProperties.getProperty("storeFile"))
                storePassword = debugSigningProperties.getProperty("storePassword")
                keyAlias = debugSigningProperties.getProperty("keyAlias")
                keyPassword = debugSigningProperties.getProperty("keyPassword")
            }
        }

        create("release") {
            if (hasReleaseSigning) {
                storeFile = rootProject.file(releaseSigningProperties.getProperty("storeFile"))
                storePassword = releaseSigningProperties.getProperty("storePassword")
                keyAlias = releaseSigningProperties.getProperty("keyAlias")
                keyPassword = releaseSigningProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }

        getByName("profile") {
            signingConfig =
                if (hasReleaseSigning) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }

        getByName("release") {
            signingConfig =
                if (hasReleaseSigning) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }
}

flutter {
    source = "../.."
}
