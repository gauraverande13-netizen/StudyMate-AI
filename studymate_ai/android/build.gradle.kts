allprojects {
    repositories {
        google()
        mavenCentral()
    }
    configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.15.0")
            force("androidx.core:core-ktx:1.15.0")
            force("androidx.browser:browser:1.8.0")
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    project.plugins.withId("com.android.library") {
        val ext = project.extensions.findByName("android")
        if (ext != null) {
            try {
                val m = ext.javaClass.methods.firstOrNull { it.name == "compileSdkVersion" && it.parameterCount == 1 }
                m?.invoke(ext, 36)
            } catch (_: Exception) {}
            try {
                val m2 = ext.javaClass.methods.firstOrNull { it.name == "setCompileSdk" && it.parameterCount == 1 }
                m2?.invoke(ext, 36)
            } catch (_: Exception) {}
        }
    }
    project.plugins.withId("com.android.application") {
        val ext = project.extensions.findByName("android")
        if (ext != null) {
            try {
                val m = ext.javaClass.methods.firstOrNull { it.name == "compileSdkVersion" && it.parameterCount == 1 }
                m?.invoke(ext, 36)
            } catch (_: Exception) {}
            try {
                val m2 = ext.javaClass.methods.firstOrNull { it.name == "setCompileSdk" && it.parameterCount == 1 }
                m2?.invoke(ext, 36)
            } catch (_: Exception) {}
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
