allprojects {
    repositories {
        google()
        mavenCentral()
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
// Plugin Flutter yang lebih baru (mis. tflite_flutter untuk cocok-wajah)
// meng-compile Kotlin ke JVM 17, sementara task Java modul yang sama tetap 1.8
// karena AGP — Gradle menolaknya dengan "Inconsistent JVM-target compatibility"
// dan build rilis GAGAL.
//
// Nilai seragam TIDAK bisa: plugin campur-campur — tflite_flutter memakai Java
// 1.8 sementara google_maps_flutter_android sudah 17, jadi memaksa semua ke 1.8
// hanya memindahkan error ke modul lain. Angkat SEMUA modul ke 17 lewat
// ekstensi AGP (`compileOptions`), bukan lewat `tasks.withType<JavaCompile>` —
// setelan ekstensi itulah yang dipakai AGP saat menyusun task, sedangkan
// konfigurasi task dari sini ditimpa dan tidak berpengaruh.
//
// WAJIB berada SEBELUM blok `evaluationDependsOn(":app")` di bawah: blok itu
// memaksa proyek dievaluasi lebih awal, dan mendaftarkan `afterEvaluate` pada
// proyek yang sudah terevaluasi langsung melempar error.
subprojects {
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
