// Standard Flutter Android build configuration
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Firebase classpath removed - using local authentication
        // classpath("com.google.gms:google-services:4.4.0")
    }
}

// Set Java version for all projects


// plugins {
//     id("org.gradle.toolchains.foojay-resolver-convention") version("0.7.0")
// } // Moved to settings.gradle.kts

// ✅ Java toolchain configuration removed - handled per subproject

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    afterEvaluate {
        if (project.name == "app") {
            // App-specific configuration if needed
        }
    }

    // ✅ Use Java 17 for all subprojects
    plugins.withType<JavaPlugin> {
        configure<JavaPluginExtension> {
            toolchain {
                languageVersion = JavaLanguageVersion.of(17)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
