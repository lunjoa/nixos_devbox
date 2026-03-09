{ pkgs, flakeUrl, ... }:

let
  firstBootScript = pkgs.writeShellScript "devbox-first-boot" ''
    # Wait for cloud-init to finish writing /etc/nixos/local.nix
    TIMEOUT=300
    ELAPSED=0
    while [ ! -f /etc/nixos/local.nix ] && [ $ELAPSED -lt $TIMEOUT ]; do
      sleep 2
      ELAPSED=$((ELAPSED + 2))
    done

    if [ ! -f /etc/nixos/local.nix ]; then
      echo "ERROR: cloud-init did not create /etc/nixos/local.nix within ''${TIMEOUT}s" >&2
      exit 1
    fi

    # Rebuild with the full devbox configuration
    ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake ${flakeUrl}#devbox
  '';
in
{
  # One-shot service that runs after cloud-init on first boot
  systemd.services.devbox-first-boot = {
    description = "Apply devbox configuration after cloud-init provisioning";
    wantedBy = [ "multi-user.target" ];
    after = [ "cloud-final.service" "network-online.target" ];
    wants = [ "network-online.target" ];

    # Only run once — creates a stamp file after success
    unitConfig.ConditionPathExists = "!/var/lib/devbox-first-boot-done";

    serviceConfig = {
      Type = "oneshot";
      ExecStart = firstBootScript;
      ExecStartPost = "${pkgs.coreutils}/bin/touch /var/lib/devbox-first-boot-done";
      TimeoutStartSec = "600";
      RemainAfterExit = true;
    };
  };
}
