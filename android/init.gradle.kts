// Global init script for Gradle to configure repositories for all projects
// Note: With Gradle 8.x and PREFER_PROJECT repository mode,
// repository configuration should be done in settings.gradle.kts
settingsEvaluated {
    settings.pluginManagement {
        repositories {
            google()
            mavenCentral()
            gradlePluginPortal()
        }
    }
}
