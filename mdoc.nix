{ coursier-tools }:

let
  cats = coursier-tools.coursierFetch {
    pname = "cats";
    version = "2.8.0";
    artifact = "org.typelevel:cats-core_2.13:2.8.0";
    sha256 = "sha256-LEs/kHaTfQwQhs4vqCcW0n+ONJPl636amaXcwwEZgOA=";
  };
  version = "2.3.6";

in
coursier-tools.coursierBootstrap {
  pname = "mdoc";
  inherit version;
  artifact = "org.scalameta:mdoc_2.13:${version}";
  mainClass = "mdoc.Main";
  sha256 = "sha256-bEknmJunzR389zACjzeSSKGvl+fwW27lUKvtCGh9Y+A=";
  propagatedBuildInputs = [ cats ];
}

