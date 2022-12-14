# `niks`

niks is an overly simplified `nix profile` wrapper that allows you to manage the
`flake:nixpkgs` part of your profile like you would with any other package manager:

```sh
niks install deno
niks remove nodejs
```

Packages not from nixpkgs are explicitly ignored and unsupported,
yet support under a flag such as `--flake` may be added in the future.

## Running

You can simply try niks out by running:

```sh
nix run github:satoqz/niks
```

## Installation

### Via `nix profile` (ironically)

```
nix profile install github:satoqz/niks#niks
```

### Via flake

In your `flake.nix`:

```nix
{
  inputs.niks.url = "github:satoqz/niks#niks";
}
```

In your system/home/whatever configuration:

```nix
{ pkgs, ... }: {
  packages = [inputs.niks.packages.${pkgs.system}.niks];
}
```

## Usage

```sh
  Usage:   niks 
  Version: 0.1.0

  Description:

    niks - command line wrapper around `nix profile`, because it sucks.

  Options:

    -h, --help     - Show this help.                            
    -V, --version  - Show the version number for this program.  

  Commands:

    help         [command]  - Show this help or the help of a sub-command.
    completions             - Generate shell completions.                 
    list, l                 - List installed packages.                    
    install, i   <pkgs...>  - Install packages.                           
    remove, r    <pkgs...>  - Remove packages.                            
    upgrade, u   [pkgs...]  - Upgrade packages.                           
```
