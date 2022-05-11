{
  inputs.nixpkgs .url = "github:nixos/nixpkgs/29b0d4d0b600f8f5dd0b86e3362a33d4181938f9";
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
          buildInputs = with pkgs; [ git gems ];
        };
    });
}
