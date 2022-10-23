{
  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      inherit (pkgs.callPackage ./coursier.nix { }) coursier-tools;

      mdoc = coursier-tools.coursierBootstrap {
        pname = "mdoc";
        version = "2.3.6";
        artifact = "org.scalameta:mdoc_2.13";
        mainClass = "mdoc.Main";
        sha256 = "sha256-bEknmJunzR389zACjzeSSKGvl+fwW27lUKvtCGh9Y+A=";
      };

      cats = coursier-tools.coursierFetch {
        pname = "cats";
        version = "2.8.0";
        artifact = "org.typelevel:cats-core_2.13";
        sha256 = "sha256-LEs/kHaTfQwQhs4vqCcW0n+ONJPl636amaXcwwEZgOA=";
      };

      mdoc-watch = pkgs.runCommand "mdoc-watch"
        {
          buildInputs = [ pkgs.jre mdoc cats ];
        }
        ''
          mkdir -p $out/bin
          echo "mdoc --in mdoc --out content --classpath $CLASSPATH --watch" > $out/bin/mdoc-watch
          chmod +x $out/bin/mdoc-watch
        '';
    in
    {
      devShells.default = pkgs.mkShell {
        buildInputs = [ mdoc cats mdoc-watch ];
      };
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
