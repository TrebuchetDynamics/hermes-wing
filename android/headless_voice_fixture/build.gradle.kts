plugins {
    id("com.android.application")
    id("kotlin-android")
}

android {
    namespace = "com.trebuchetdynamics.hermes.wing.voicefixture"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.trebuchetdynamics.hermes.wing.voicefixture"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }
}
