{
  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils, ... }: flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-darwin" ] (system:
    let
      pkgs = import nixpkgs { inherit system; };
      inherit (pkgs.callPackage ./coursier.nix { }) coursier-tools;

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

      mdoc_outputs = pkgs.stdenv.mkDerivation {
        name = "blog-mdoc-outputs";
        buildInputs = [ mdoc cats pkgs.jre ];
        src = ./mdoc;
        COURSIER_CACHE = ".nix/COURSIER_CACHE";

        buildPhase = ''
          mdoc --in . --classpath $CLASSPATH
        '';
        installPhase = "cp -r out $out";
      };
    in
    {
      devShells.default = pkgs.mkShell {
        buildInputs = [ pkgs.zola mdoc ];
      };

      # Intermediate package
      packages.mdoc_outputs = mdoc_outputs;

      packages.default = pkgs.stdenv.mkDerivation {
        name = "kubukoz-blog";
        buildInputs = [ pkgs.zola ];
        src = self;

        inherit mdoc_outputs;
        buildPhase = ''
          cp $mdoc_outputs/* content
          zola build
        '';

        installPhase = "cp -r public $out";
      };

      checks.default = self.packages.${system}.default;
    });
}
