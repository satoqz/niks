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
        niks = pkgs.stdenv.mkDerivation {
          pname = "niks";
          version = "0.1.0";
          src = ./.;

          installPhase = ''
            mkdir -p $out/src $out/bin
            cp -r *.ts $out/src

            echo "#!${pkgs.bash}/bin/bash" >> $out/bin/niks
            echo "DENO_NO_UPDATE_CHECK=1 ${pkgs.deno}/bin/deno run --allow-run $out/src/cli.ts \"\$@\"" >> $out/bin/niks

            chmod +x $out/bin/niks
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
