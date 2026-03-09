{ nixpkgs, home-manager, ... }:

let
  # The remote flake URL — single source of truth for all modules
  flakeUrl = "github:org/nixos_devbox";

  # Shared module list used by both nixosConfigurations and image builds
  devboxModules = [
    ../modules/base.nix
    ../modules/vm.nix
    ../modules/shell.nix
    ../modules/vscode.nix
    ../modules/podman.nix
    ../modules/first-boot.nix
    ../modules/development/node.nix
    ../modules/development/python.nix
    ../users/default.nix
    ../profiles/default.nix
    home-manager.nixosModules.home-manager
    {
      nixpkgs.overlays = [ (import ../overlays/default.nix) ];
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
    }
  ];
in
{
  inherit devboxModules flakeUrl;

  # Build a full nixosConfiguration for a devbox
  mkConfig = { hostname }:
    nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit flakeUrl; };
      modules = devboxModules ++ [
        { networking.hostName = hostname; }
      ];
    };
}
