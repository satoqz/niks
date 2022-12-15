{
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.deno2nix.url = "github:SnO2WMaN/deno2nix";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    deno2nix,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [deno2nix.overlays.default];
      };
    in rec {
      packages = let
        version = "0.1.0";
        executable = pkgs.deno2nix.mkExecutable {
          inherit version;
          pname = "niks-executable";

          src = ./.;
          bin = "niks";

          entrypoint = "./cli.ts";
          lockfile = "./deno.lock";
          config = "./deno.json";

          allow.run = true;
        };
      in {
        niks = pkgs.stdenv.mkDerivation {
          inherit version;
          pname = "niks";
          src = executable;

          nativeBuildInputs = [pkgs.installShellFiles];

          installPhase = ''
            install -Dm755 -t $out/bin $src/bin/niks
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
        buildInputs = [pkgs.deno];
      };

      formatter = pkgs.alejandra;
    });
}
