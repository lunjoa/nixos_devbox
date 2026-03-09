{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nodejs_20
    # Global npm packages — add entries here to make them available system-wide
    # Find package names with: nix search nixpkgs nodePackages
    nodePackages.typescript
  ];
}
