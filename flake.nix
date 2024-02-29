{
  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils, ... }: flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-darwin" ] (system:
    let
      pkgs = import nixpkgs { inherit system; };
      mdoc = pkgs.callPackage ./mdoc.nix { inherit (pkgs.callPackage ./coursier.nix { }) coursier-tools; };
      page = { base-url ? null }: pkgs.stdenv.mkDerivation {
        name = "kubukoz-blog";
        buildInputs = [ pkgs.zola ];
        src = self;

        inherit (mdoc) mdoc_outputs;
        buildPhase =
          let baseUrlString = if base-url == null then "" else "--base-url ${base-url}"; in
          ''
            cp -rL $mdoc_outputs/* content
            ls -alG $mdoc_outputs
            zola build --output-dir $out ${baseUrlString}
          '';

        dontInstall = true;
      };
    in
    {
      # Intermediate package with just mdoc, for "watch" mode
      packages.mdoc_outputs = mdoc.mdoc_outputs;

      packages.default = page { };
      packages.preview = page { base-url = "https://blog.kubukoz.com/preview"; };

      devShells.generate_shas = pkgs.mkShell { packages = with pkgs; [ scala-cli coursier nix ]; };

      checks.default = self.packages.${system}.default;
    });
}
