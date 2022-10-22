{
  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      gems = pkgs.bundlerEnv {
        name = "blog-gems";
        inherit (pkgs) ruby;
        gemdir = ./.;
      };
    in
    {
      devShells.default =
        pkgs.mkShell {
          buildInputs = [ pkgs.zola ];
        };
      packages.default = pkgs.stdenv.mkDerivation
        {
          pname = "kubukoz-blog";
          version = "1.0.0";
          buildInputs = [ pkgs.zola ];
          src = ./.;
          buildPhase = "zola build";
          installPhase = "cp -r public $out";
        };
    });
}
