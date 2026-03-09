{ pkgs, ... }:

{
  # Podman — rootless, daemonless container runtime
  virtualisation.podman = {
    enable = true;
    # Create a `docker` alias for podman (CLI compatibility)
    dockerCompat = true;
  };

  # podman-compose for docker-compose compatibility
  environment.systemPackages = with pkgs; [
    podman-compose
  ];
}
