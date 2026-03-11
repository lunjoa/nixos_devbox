{
  description = "NixOS developer devbox for OpenStack VMs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-generators, ... }:
    let
      system = "x86_64-linux";
      devbox = import ./lib/mkDevbox.nix { inherit nixpkgs; };
      rev = self.rev or null;
    in
    {
      nixosConfigurations.devbox = devbox.mkConfig {
        hostname = "devbox";
        configurationRevision = rev;
      };

      packages.${system}.image = nixos-generators.nixosGenerate {
        inherit system;
        format = "openstack";
        modules = devbox.devboxModules ++ [
          { networking.hostName = "devbox"; }
        ];
      };

      checks.${system}.build =
        self.nixosConfigurations.devbox.config.system.build.toplevel;
    };
}
