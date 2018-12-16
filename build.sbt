import com.typesafe.sbt.SbtNativePackager.autoImport.NativePackagerHelper._
import com.typesafe.sbt.packager.docker._
import sbt.file

name := "aerospike-schema-evolution"

version := "0.1"

scalaVersion := "2.12.8"

lazy val root = project.in(file("."))
  .enablePlugins(JavaAppPackaging)
  .settings(
    mappings in Universal := (mappings in Universal).value ++: directory(baseDirectory.value / "aerospike"),
    dockerBaseImage := "aerospike/aerospike-tools:latest",
    dockerCommands ++= Seq(
      Cmd("COPY", "/opt/docker/aerospike/scripts/autoMigrate.sh", "/usr/local/bin/autoMigrate"),
      Cmd("COPY", "/opt/docker/aerospike/scripts/execute-aql.sh", "/usr/local/bin/execute-aql"),
      Cmd("COPY", "/opt/docker/aerospike/aql", "/aql"),
      Cmd("USER", "root"),
      Cmd("RUN", """["mkdir", "/usr/sbin/.aerospike"]"""),
      Cmd("RUN", """["chmod", "755", "/usr/local/bin/autoMigrate"]"""),
      Cmd("RUN", """["chmod", "755", "/usr/local/bin/execute-aql"]"""),
      Cmd("USER", "daemon")
    ),
    dockerEntrypoint := Seq("autoMigrate"),
    dockerRepository := Some("change_to_your_repository")
  )