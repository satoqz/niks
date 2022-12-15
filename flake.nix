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
      buildInputs = [pkgs.deno];
    in rec {
      packages = {
        niks = pkgs.stdenv.mkDerivation {
          pname = "niks";
          version = "0.1.0";
          src = ./.;

          inherit buildInputs;
          nativeBuildInputs = [pkgs.installShellFiles];

          buildPhase = ''
            export DENO_DIR=/tmp/niks-deno-dir
            mkdir -p $DENO_DIR

            deno compile --allow-run -o niks cli.ts
          '';

          installPhase = ''
            install -Dm755 -t $out/bin niks
            runHook postInstall
          '';

          postInstall = ''
            installShellCompletion --cmd niks \
              --bash <($out/bin/niks completions bash) \
              --zsh <($out/bin/niks completions zsh) \
              --fish <($out/bin/niks completions fish)
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
        inherit buildInputs;
      };

      formatter = pkgs.alejandra;
    });
}