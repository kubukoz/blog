{
  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils, ... }: flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-darwin" ] (system:
    let
      pkgs = import nixpkgs { inherit system; };
      mdoc = pkgs.callPackage ./mdoc.nix { inherit (pkgs.callPackage ./coursier.nix { }) coursier-tools; };
    in
    {
      # Intermediate package with just mdoc, for "watch" mode
      packages.mdoc_outputs = mdoc.mdoc_outputs;

      packages.default = pkgs.stdenv.mkDerivation {
        name = "kubukoz-blog";
        buildInputs = [ pkgs.zola ];
        src = self;

        inherit (mdoc) mdoc_outputs;
        buildPhase = ''
          cp $mdoc_outputs/* content
          zola build
        '';

        installPhase = "cp -r public $out";
      };

      checks.default = self.packages.${system}.default;
    });
}
