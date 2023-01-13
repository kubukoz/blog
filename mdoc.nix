{ stdenv, jre, coursier-tools, lib, linkFarm }:
let
  mdoc = coursier-tools.make-runnable {
    launcher = coursier-tools.coursier-fetch {
      pname = "mdoc";
      version = "2.3.6";
      artifact = "org.scalameta:mdoc_2.13";
      sha256 = "sha256-bEknmJunzR389zACjzeSSKGvl+fwW27lUKvtCGh9Y+A=";
    };
    mainClass = "mdoc.Main";
  };

  mkMdocDerivation = { name, src, buildInputs ? [ ] }: stdenv.mkDerivation {
    inherit name src;
    dontUnpack = true;
    buildInputs = [ mdoc jre ] ++ buildInputs;
    COURSIER_CACHE = ".nix/COURSIER_CACHE";

    buildPhase =
      ''
        # copilot wrote this.
        classpathStr=$(
          if [ -z "$CLASSPATH" ]; then
            echo "";
          else
            echo "--classpath $CLASSPATH";
          fi
        )

        mdoc --in $src $classpathStr
      '';
    installPhase = "cp -r out $out";
  };

  mdoc_outputs =
    let
      # Map a directory of files to a directory of derivations.
      # The result is an attrset.
      mapFilesRelativeBase =
        { f # function that maps file to derivation
        , baseDirectory
        ,
        }:
        builtins.mapAttrs
          (filename: filetype:
          # TODO: support subdirectories when needed.
            assert filetype == "regular";
            {
              name = filename;
              path = f ("${baseDirectory}/${filename}");
            }
          )
          (builtins.readDir baseDirectory);
      # Map a directory of files to a directory of derivations.
      mapFilesRelative =
        { name
        , f # function that maps file to derivation
        , baseDirectory
        }@args:
        linkFarm
          name
          (lib.attrValues (
            mapFilesRelativeBase (builtins.removeAttrs args [ "name" ])
          ));

      buildInputsFor = src:
        let
          libRegistry =
            builtins.mapAttrs
              (pname: value: coursier-tools.coursier-fetch (value // { inherit pname; }))
              (builtins.fromJSON (builtins.readFile ./mdoc-lib-index.json));

          document = builtins.readFile src;
          sections = builtins.split "\\+\\+\\+" document;
          frontmatter = builtins.elemAt sections 2;
          decoded = builtins.fromTOML frontmatter;
          libNames = (decoded.extra or { }).scalaLibs or [ ];
        in
        builtins.map (libname: libRegistry.${libname}) libNames;

      f = (src:
        mkMdocDerivation {
          name = "
          mdoc-${builtins.baseNameOf src}";
          buildInputs = buildInputsFor src;
          inherit src;
        }
      );

    in
    mapFilesRelative
      {
        name = "mdoc-out";
        inherit f;
        baseDirectory = ./mdoc;
      } // builtins.mapAttrs (_: value: value.path) (mapFilesRelativeBase {
      inherit f;
      baseDirectory = ./mdoc;
    });
in
{ inherit mdoc mdoc_outputs; }


