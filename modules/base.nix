{ lib, pkgs, flakeUrl, ... }:

let
  updateCheckScript = pkgs.writeShellScript "devbox-update-check" ''
    STATE_FILE="/var/lib/devbox-update-status"

    # Get the current system's flake last modified timestamp
    if ! CURRENT=$(${pkgs.nix}/bin/nix flake metadata --json \
      | ${pkgs.jq}/bin/jq -r '.lastModified // empty'); then
      echo "Warning: failed to read current flake metadata" >&2
      exit 0
    fi

    # Get the remote flake's last modified timestamp
    if ! REMOTE=$(${pkgs.nix}/bin/nix flake metadata ${flakeUrl} --json --refresh \
      | ${pkgs.jq}/bin/jq -r '.lastModified // empty'); then
      echo "Warning: failed to fetch remote flake metadata (network issue?)" >&2
      exit 0
    fi

    if [ -n "$CURRENT" ] && [ -n "$REMOTE" ] && [ "$REMOTE" -gt "$CURRENT" ]; then
      echo "update_available" > "$STATE_FILE"
    else
      rm -f "$STATE_FILE"
    fi
  '';
in
{
  system.stateVersion = "25.11";

  # Locale and timezone
  time.timeZone = "Europe/Stockholm";
  i18n.defaultLocale = "sv_SE.UTF-8";

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages (some VS Code extensions need this)
  nixpkgs.config.allowUnfree = true;

  # System packages available to all users
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    vim
    htop
    tmux
    jq
    yq
    unzip
    tree
    ripgrep
    fd
    # Networking & diagnostics
    dnsutils      # dig, nslookup
    traceroute
    inetutils     # telnet, ping, hostname
    nmap
    tcpdump
    whois
    # System tools
    lsof
    strace
    file
    openssl
  ];

  # SSH server — key-only authentication
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = lib.mkForce "no";
      AllowTcpForwarding = true;
    };
  };

  # Firewall
  networking.firewall.allowedTCPPorts = [ 22 ];

  # Nix garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Update checker — runs every 4 hours
  systemd.services.devbox-update-check = {
    description = "Check for devbox configuration updates";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = updateCheckScript;
    };
  };

  systemd.timers.devbox-update-check = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "4h";
    };
  };

  # Login banner — shows update notification if available
  environment.etc."profile.d/devbox-update-notice.sh" = {
    text = ''
      if [ -f /var/lib/devbox-update-status ]; then
        echo ""
        echo "╔════════════════════════════════════════════════════════════════════╗"
        echo "║  DEVBOX UPDATE AVAILABLE                                          ║"
        echo "║  Run: sudo nixos-rebuild switch --flake ${flakeUrl}#devbox        ║"
        echo "╚════════════════════════════════════════════════════════════════════╝"
        echo ""
      fi
    '';
    mode = "0555";
  };

  # MOTD
  users.motd = ''
    Welcome to DevBox — NixOS Development Environment
  '';
}
