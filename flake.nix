{
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
    in rec {
      packages = {
        niks = pkgs.stdenvNoCC.mkDerivation rec {
          pname = "niks";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = [pkgs.makeWrapper];

          installPhase = ''
            mkdir -p $out/src $out/bin
            cp -r *.ts $out/src

            cp ${pkgs.writeShellScriptBin pname ''
              exec ${pkgs.deno}/bin/deno run --allow-run $SRC_PATH/cli.ts "$@"
            ''}/bin/${pname} $out/bin

            wrapProgram $out/bin/${pname} \
              --set SRC_PATH $out/src \
              --set DENO_NO_UPDATE_CHECK 1
          '';
        };

        default = packages.niks;
      };

      apps = {
        niks = flake-utils.lib.mkApp {
          drv = packages.niks;
        };

        default = apps.niks;
      };

      devShells.default = pkgs.mkShell {
        buildInputs = [pkgs.deno];
      };

      formatter = pkgs.alejandra;
    });
}
