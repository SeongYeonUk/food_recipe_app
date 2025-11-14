import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    namespace = "com.example.food_recipe_app"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions { jvmTarget = "1.8" }

    sourceSets { getByName("main") { java.srcDirs("src/main/kotlin") } }

    defaultConfig {
        applicationId = "com.example.food_recipe_app"
        // ✅ 핵심: minSdk 23 이상
        // ① 그냥 숫자로 고정
        //minSdkVersion flutter.minSdkVersion
        // ② 템플릿 변수를 쓰고 싶다면 (아래 gradle.properties도 같이 수정)
        // minSdk = flutter.minSdkVersion.toInt()
        minSdk = 24
        targetSdk = 34
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter { source = "../.." }

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
