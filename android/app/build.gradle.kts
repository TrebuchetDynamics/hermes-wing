import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties().apply {
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.isFile) {
        localPropertiesFile.inputStream().use(::load)
    }
}

fun releaseSigningValue(propertyName: String, environmentName: String): String? {
    return (localProperties.getProperty(propertyName) ?: System.getenv(environmentName))
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
}

android {
    namespace = "com.trebuchetdynamics.navivox"
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
        applicationId = "com.trebuchetdynamics.navivox"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val releaseKeystorePath = releaseSigningValue(
        "navivox.release.storeFile",
        "NAVIVOX_RELEASE_STORE_FILE",
    )
    val releaseKeystorePassword = releaseSigningValue(
        "navivox.release.storePassword",
        "NAVIVOX_RELEASE_STORE_PASSWORD",
    )
    val releaseKeyAlias = releaseSigningValue(
        "navivox.release.keyAlias",
        "NAVIVOX_RELEASE_KEY_ALIAS",
    )
    val releaseKeyPassword = releaseSigningValue(
        "navivox.release.keyPassword",
        "NAVIVOX_RELEASE_KEY_PASSWORD",
    )

    if (
        releaseKeystorePath != null &&
            releaseKeystorePassword != null &&
            releaseKeyAlias != null &&
            releaseKeyPassword != null
    ) {
        signingConfigs {
            create("release") {
                storeFile = file(releaseKeystorePath)
                storePassword = releaseKeystorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // A keystore-backed release signing config is selected when all
            // navivox.release.* local properties or NAVIVOX_RELEASE_* environment
            // variables are present. Without them, keep debug signing only for
            // local release smoke runs; do not distribute that artifact.
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    testImplementation("junit:junit:4.13.2")
}
