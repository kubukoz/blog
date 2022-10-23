{
  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      inherit (pkgs.callPackage ./coursier.nix { }) coursier-tools;
      mdoc = pkgs.callPackage ./mdoc.nix { inherit coursier-tools; };
      cats = coursier-tools.coursierFetch {
        pname = "cats";
        version = "2.8.0";
        artifact = "org.typelevel:cats-core_2.13:2.8.0";
        sha256 = "sha256-LEs/kHaTfQwQhs4vqCcW0n+ONJPl636amaXcwwEZgOA=";
      };
    in
    {
      packages.default = pkgs.stdenv.mkDerivation {
        pname = "kubukoz-blog";
        version = "1.0.0";
        buildInputs = [ pkgs.zola mdoc cats pkgs.jre ];
        src = self;
        COURSIER_CACHE = ".nix/COURSIER_CACHE";
        buildPhase = ''
          mdoc --in mdoc --out content --classpath $CLASSPATH
          zola build
        '';
        installPhase = "cp -r public $out";
      };
    });
}
