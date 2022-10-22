{
  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      inherit (pkgs.callPackage ./coursier.nix { }) coursier-tools;
      mdoc = pkgs.callPackage ./mdoc.nix { inherit coursier-tools; };
    in
    {
      devShells.default =
        pkgs.mkShell {
          buildInputs = [ pkgs.zola mdoc ];
        };
      packages.default = pkgs.stdenv.mkDerivation {
        pname = "kubukoz-blog";
        version = "1.0.0";
        buildInputs = [ pkgs.zola mdoc ];
        src = self;
        buildPhase = "zola build";
        installPhase = "cp -r public $out";
      };
    });
}
