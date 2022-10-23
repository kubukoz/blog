{ stdenv, coursier, jre, makeWrapper }:

let
  coursier-fetch = { pname, version, artifact, sha256 }:

    stdenv.mkDerivation {
      inherit pname version;
      dontUnpack = true;

      buildInputs = [ coursier jre ];

      COURSIER_CACHE = ".nix/COURSIER_CACHE";
      buildCommand = ''
        cs fetch ${artifact}:${version} > deps
        mkdir -p $out/share/java
        cp $(< deps) $out/share/java/
      '';

      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = sha256;
    };

  make-runnable = { mainClass, launcher, alias ? launcher.pname, buildInputs ? [ ], ... }@args':
    let
      argsBuildInputs = buildInputs;
      extraArgs = builtins.removeAttrs args' [ "alias" "mainClass" "buildInputs" ];
      baseArgs = {
        inherit (launcher) pname version;
        buildInputs = [ launcher jre ] ++ argsBuildInputs;
        nativeBuildInputs = [ makeWrapper ];

        buildCommand = ''
          makeWrapper ${jre}/bin/java $out/bin/${alias} \
            --add-flags "-cp $CLASSPATH ${mainClass}"

          runHook postInstall
        '';
      };
    in
    stdenv.mkDerivation (baseArgs // extraArgs);
in

{
  coursier-tools = {
    inherit coursier-fetch make-runnable;
  };
}
