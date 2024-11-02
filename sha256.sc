//> using scala "3.5.2"
//> using dep com.lihaoyi::os-lib:0.9.0
//> using dep com.lihaoyi::upickle:2.0.0
import upickle.default._

val sourceFile = os.pwd / os.RelPath(args(0))

case class PackageDef(version: String, artifact: String, sha256: String)
object PackageDef {
  implicit val rw: ReadWriter[PackageDef] = macroRW
}

def fetchHash(pkg: PackageDef): String = {
  os
    .proc(
      "bash",
      "-c",
      s"""set -e
         |cs fetch ${pkg.artifact}:${pkg.version} > deps
         |rm -rf .tmp && mkdir -p .tmp/share/java
         |cp $$(< deps) .tmp/share/java/
         |nix hash path ./.tmp
         |rm -rf .tmp deps""".stripMargin
    )
    .call(cwd = os.pwd)
    .out
    .text()
    .strip()
}

val newPackages =
  read[Map[String, PackageDef]](os.read(sourceFile)).map {
    case (name, pkg) if pkg.sha256.isBlank =>
      println(s"Package $name has no sha256. Fetching...")
      val hash = fetchHash(pkg)
      println(s"Package $name now has sha256 $hash")

      (name, pkg.copy(sha256 = hash))

    case unchanged => unchanged
  }

os.write.over(sourceFile, write(newPackages, indent = 2) + "\n")
