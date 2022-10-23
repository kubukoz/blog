{ stdenv, coursier, jre, makeWrapper }:

let
  coursierFetch = { pname, version, artifact, sha256 }:

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

  coursierBootstrap = { pname, version, artifact, alias ? pname, mainClass, sha256, buildInputs ? [ ], ... }@args':
    let
      deps = coursierFetch { pname = "${pname}-deps"; inherit version artifact sha256; };

      argsBuildInputs = buildInputs;
      extraArgs = builtins.removeAttrs args' [ "pname" "version" "artifact" "alias" "mainClass" "sha256" "buildInputs" ];
      baseArgs = {
        inherit pname version;
        buildInputs = [ deps jre ] ++ argsBuildInputs;
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
    inherit coursierFetch coursierBootstrap;
  };
}
