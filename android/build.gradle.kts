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
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Fix namespace for old plugins built against AGP 7 and earlier. AGP 8 no
// longer allows a namespace to be declared via the manifest `package=`
// attribute, which breaks packages like thermal_printer. For each library
// subproject we:
//   1. Set the Gradle-level namespace to the plugin's ORIGINAL package. This
//      must match the package the plugin's Kotlin/Java sources expect (they do
//      `import <package>.R`), otherwise the generated R class lands in the
//      wrong package and compilation fails with "Unresolved reference 'R'".
//   2. Strip the now-illegal `package=` attribute from the source manifest.
//
// Plugins whose sources reference a specific package must be listed here so we
// preserve that exact package. Everything else falls back to reading the
// manifest, then to a synthesized namespace.
val pluginPackageOverrides = mapOf(
    "thermal_printer" to "com.codingdevs.thermal_printer",
)

subprojects {
    plugins.withId("com.android.library") {
        val android = extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
        val manifest = file("src/main/AndroidManifest.xml")

        // Recover the original package from an explicit override first, then
        // from the manifest's `package=` attribute if still present.
        val manifestText = if (manifest.exists()) manifest.readText() else null
        val manifestPkg = manifestText
            ?.let { Regex("""package="([^"]*)"""").find(it)?.groupValues?.get(1) }
        val originalPkg = pluginPackageOverrides[project.name] ?: manifestPkg

        if (android.namespace == null) {
            android.namespace = originalPkg
                ?: "com.plugin.${project.name.replace("-", "_").replace("_", "")}"
        }

        // Strip the `package=` attribute AGP 8 refuses to accept.
        if (manifestText != null && manifestText.contains(Regex("""\s+package="[^"]*""""))) {
            manifest.writeText(manifestText.replace(Regex("""\s+package="[^"]*""""), ""))
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
