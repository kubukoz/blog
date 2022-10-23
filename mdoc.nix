{ stdenv, jre, coursier-tools }:
let
  mdoc = coursier-tools.make-runnable {
    launcher = coursier-tools.coursier-fetch {
      pname = "mdoc";
      version = "2.3.6";
      artifact = "org.scalameta:mdoc_2.13";
      sha256 = "sha256-bEknmJunzR389zACjzeSSKGvl+fwW27lUKvtCGh9Y+A=";
    };
    mainClass = "mdoc.Main";
  };

  cats = coursier-tools.coursier-fetch {
    pname = "cats";
    version = "2.8.0";
    artifact = "org.typelevel:cats-core_2.13";
    sha256 = "sha256-LEs/kHaTfQwQhs4vqCcW0n+ONJPl636amaXcwwEZgOA=";
  };

  mdoc_outputs = stdenv.mkDerivation {
    name = "blog-mdoc-outputs";
    buildInputs = [ mdoc cats jre ];
    src = ./mdoc;
    COURSIER_CACHE = ".nix/COURSIER_CACHE";

    buildPhase = ''
      mdoc --in . --classpath $CLASSPATH
    '';
    installPhase = "cp -r out $out";
  };
in
{ inherit mdoc mdoc_outputs; }
