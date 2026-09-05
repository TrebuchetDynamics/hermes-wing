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
    namespace = "com.trebuchetdynamics.hermes.wing"
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
        applicationId = "com.trebuchetdynamics.hermes.wing"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val releaseKeystorePath = releaseSigningValue(
        "wing.release.storeFile",
        "WING_RELEASE_STORE_FILE",
    )
    val releaseKeystorePassword = releaseSigningValue(
        "wing.release.storePassword",
        "WING_RELEASE_STORE_PASSWORD",
    )
    val releaseKeyAlias = releaseSigningValue(
        "wing.release.keyAlias",
        "WING_RELEASE_KEY_ALIAS",
    )
    val releaseKeyPassword = releaseSigningValue(
        "wing.release.keyPassword",
        "WING_RELEASE_KEY_PASSWORD",
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
        debug {
            // Device regressions must not replace a user's paired installation.
            if (providers.environmentVariable("WING_ISOLATED_DEVICE_TEST").orNull == "1") {
                applicationIdSuffix = ".qa"
            }
        }
        release {
            // A keystore-backed release signing config is selected when all
            // wing.release.* local properties or WING_RELEASE_* environment
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

// Flutter's integration target can leave its dev-only plugin in the generated
// main-source registrant. Release Gradle excludes dev plugins, so strip only
// that generated block after Flutter compilation and before javac. Debug and
// integration builds keep their normal registration.
val releasePluginRegistrant =
    layout.projectDirectory.file(
        "src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java",
    )
val stripIntegrationTestFromReleaseRegistrant by tasks.registering {
    doLast {
        val registrant = releasePluginRegistrant.asFile
        if (!registrant.isFile) return@doLast
        val integrationTestBlock =
            """    try {
      flutterEngine.getPlugins().add(new dev.flutter.plugins.integration_test.IntegrationTestPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin integration_test, dev.flutter.plugins.integration_test.IntegrationTestPlugin", e);
    }
"""
        val source = registrant.readText()
        if (!source.contains("dev.flutter.plugins.integration_test")) return@doLast
        val releaseSource = source.replace(integrationTestBlock, "")
        check(!releaseSource.contains("dev.flutter.plugins.integration_test")) {
            "Flutter changed the integration_test registrant format."
        }
        registrant.writeText(releaseSource)
    }
}

tasks.matching { it.name == "compileFlutterBuildRelease" }.configureEach {
    finalizedBy(stripIntegrationTestFromReleaseRegistrant)
}
tasks.matching { it.name == "compileReleaseJavaWithJavac" }.configureEach {
    dependsOn(stripIntegrationTestFromReleaseRegistrant)
}

dependencies {
    implementation("com.google.android.gms:play-services-code-scanner:16.1.0")
    implementation("com.google.android.gms:play-services-mlkit-barcode-scanning:18.3.1")
    testImplementation("junit:junit:4.13.2")
}
