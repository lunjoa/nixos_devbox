{ nixpkgs, ... }:

let
  # Shared module list used by both nixosConfigurations and image builds
  devboxModules = [
    ../modules/base.nix
    ../modules/vm.nix
    ../modules/shell.nix
    ../modules/vscode.nix
    ../modules/podman.nix
    ../modules/development/node.nix
    ../modules/development/python.nix
    ../users/default.nix
    ../profiles/default.nix
    {
      nixpkgs.overlays = [ (import ../overlays/default.nix) ];
    }
  ];
in
{
  inherit devboxModules;

  # Build a full nixosConfiguration for a devbox
  mkConfig = { hostname }:
    nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = devboxModules ++ [
        { networking.hostName = hostname; }
      ];
    };
}
