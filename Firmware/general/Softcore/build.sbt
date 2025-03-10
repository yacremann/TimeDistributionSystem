
val spinalVersion = "1.4.0" // 1.2.0

name := "VexRISCVSoftcore"

//def scalaSources(base: File): PathFinder = (base / "scala") ** "*.scala"

organization := "com.github.spinalhdl"
version := "2.0.0" //"1.0"
scalaVersion := "2.11.12" // "2.11.6"

// EclipseKeys.withSource := true

libraryDependencies ++= Seq(
  "com.github.spinalhdl" % "spinalhdl-core_2.11" % spinalVersion,
  "com.github.spinalhdl" % "spinalhdl-lib_2.11" % spinalVersion,
  compilerPlugin("com.github.spinalhdl" % "spinalhdl-idsl-plugin_2.11" % spinalVersion),
  "org.scalatest" % "scalatest_2.11" % "2.2.1",
  "org.yaml" % "snakeyaml" % "1.8"
)

//addCompilerPlugin("org.scala-lang.plugins" % "scala-continuations-plugin_2.11.6" % "1.0.2")
//scalacOptions += "-P:continuations:enable"

fork := true

lazy val root = (project in file("."))
  .dependsOn(vexRISCV)
lazy val vexRISCV = RootProject(uri("https://github.com/SpinalHDL/VexRiscv.git"))
