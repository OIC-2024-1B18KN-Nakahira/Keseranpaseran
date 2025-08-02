allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.set(file("../build"))

subprojects {
    project.layout.buildDirectory.set(File(rootProject.layout.buildDirectory.get().asFile, project.name))
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}