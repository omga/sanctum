import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing credentials.
//
// Read from android/key.properties, which is gitignored, or from the
// environment when it is not present — that is what CI uses, and it is
// why nothing here has a default. The keystore itself lives outside the
// repository entirely: android/.gitignore covers `**/*.jks`, but those
// patterns are relative to android/, so a keystore dropped at the
// repository root is *not* ignored and is one `git add .` away from
// being public forever.
//
// If neither source is available the release build falls back to the
// debug keystore so `flutter run --release` still works on a machine
// with no signing material. That build is fine for local testing and is
// rejected by Play, which is the correct outcome — an unsigned-for-real
// release should fail loudly at upload, not ship.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

fun signingValue(key: String, env: String): String? =
    keystoreProperties.getProperty(key) ?: System.getenv(env)

val releaseStoreFile = signingValue("storeFile", "SANCTUM_STORE_FILE")
val hasReleaseSigning = releaseStoreFile != null && file(releaseStoreFile).exists()

android {
    namespace = "com.soulheals.sanctum"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications, which uses java.time
        // APIs that predate the app's minSdk.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.soulheals.sanctum"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = signingValue("storePassword", "SANCTUM_STORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "SANCTUM_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "SANCTUM_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "No release signing config found — falling back to the " +
                        "debug keystore. This build cannot be uploaded to Play."
                )
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
