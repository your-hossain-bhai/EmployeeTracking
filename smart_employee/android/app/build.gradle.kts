// build.gradle.kts (app level)
// Android Application Build Configuration
//
// This file configures the Android build for the Smart Employee app.
// It sets up plugins, dependencies, and build configurations.

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Apply the Flutter Gradle plugin
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "smart.attendance"
    compileSdk = 35
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Enable core library desugaring
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "smart.attendance"
        minSdk = 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Signing config for release builds
            signingConfig = signingConfigs.getByName("debug")
            // Enable minification for release
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring for Java 8+ APIs on older Android versions
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // Google Play Services - Location (still needed for geolocator)
    implementation("com.google.android.gms:play-services-location:21.1.0")
    
    // NOTE: Removed Google Maps SDK - using flutter_map with MapTiler instead
    // implementation("com.google.android.gms:play-services-maps:18.2.0")
    
    // Firebase (BOM for version management)
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-analytics")
    
    // Kotlin coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.7.3")
    
    // MultiDex support
    implementation("androidx.multidex:multidex:2.0.1")
}
