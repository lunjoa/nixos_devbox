{ pkgs, ... }:

let
  # Allocate subuid/subgid ranges for users in the podman group.
  # Cloud-init creates users at runtime, so NixOS's declarative subUidRanges
  # cannot be used. This script runs at boot and on reactivation to ensure
  # any cloud-init-created user gets the ranges Podman needs.
  setupSubids = pkgs.writeShellScript "podman-subids" ''
    for user in $(${pkgs.gawk}/bin/awk -F: '$4 == podgid {print $1}' podgid="$(${pkgs.getent}/bin/getent group podman | cut -d: -f3)" /etc/passwd); do
      if ! grep -q "^$user:" /etc/subuid 2>/dev/null; then
        ${pkgs.shadow}/bin/usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$user"
      fi
    done
  '';
in
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

  # Allocate subuid/subgid ranges for cloud-init-created users
  systemd.services.podman-subids = {
    description = "Allocate subuid/subgid for rootless Podman users";
    wants = [ "cloud-final.service" ];
    after = [ "cloud-final.service" ];
    wantedBy = [ "multi-user.target" "sysinit-reactivation.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = setupSubids;
    };
  };
}
