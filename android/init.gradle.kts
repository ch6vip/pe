// Global init script for Gradle to configure repositories for all projects
settingsEvaluated {
    settings.pluginManagement {
        repositories {
            google()
            mavenCentral()
            gradlePluginPortal()
        }
    }
}

allprojects {
    buildscript {
        repositories {
            google()
            mavenCentral()
            gradlePluginPortal()
        }
    }
    repositories {
        google()
        mavenCentral()
    }
}
