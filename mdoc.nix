{ coursier-tools }:

let
  version = "2.3.6"; in

coursier-tools.coursierBootstrap {
  pname = "mdoc";
  inherit version;
  artifact = "org.scalameta:mdoc_2.12:${version}";
  mainClass = "mdoc.Main";
  sha256 = "sha256-4IlaQwA1a5PJaNR4epTsAF9mjd5j467z6AQRcuKuzDw=";
}

