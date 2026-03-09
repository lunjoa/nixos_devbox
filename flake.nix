{
  description = "NixOS developer devbox for OpenStack VMs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixos-generators, ... }:
    let
      system = "x86_64-linux";
      devbox = import ./lib/mkDevbox.nix { inherit nixpkgs home-manager; };
    in
    {
      nixosConfigurations.devbox = devbox.mkConfig {
        hostname = "devbox";
      };

      packages.${system}.image = nixos-generators.nixosGenerate {
        inherit system;
        format = "openstack";
        specialArgs = { inherit (devbox) flakeUrl; };
        modules = devbox.devboxModules ++ [
          { networking.hostName = "devbox"; }
        ];
      };

      checks.${system}.build =
        self.nixosConfigurations.devbox.config.system.build.toplevel;
    };
}
