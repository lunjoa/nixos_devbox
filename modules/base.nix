{ lib, pkgs, ... }:

let
  flakeUrl = "github:lunjoa/nixos_devbox";

  updateCheckScript = pkgs.writeShellScript "devbox-update-check" ''
    STATE_FILE="/var/lib/devbox-update-status"

    # Get the current system's flake revision
    CURRENT=$(${pkgs.nix}/bin/nix flake metadata --json /run/current-system 2>/dev/null \
      | ${pkgs.jq}/bin/jq -r '.locks.nodes.root.locked.rev // empty')

    # Get the remote flake's latest revision
    REMOTE=$(${pkgs.nix}/bin/nix flake metadata ${flakeUrl} --json --refresh 2>/dev/null \
      | ${pkgs.jq}/bin/jq -r '.locked.rev // empty')

    if [ -z "$CURRENT" ] || [ -z "$REMOTE" ]; then
      exit 0
    fi

    if [ "$CURRENT" != "$REMOTE" ]; then
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
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_MEASUREMENT = "sv_SE.UTF-8";
    LC_MONETARY = "sv_SE.UTF-8";
    LC_NUMERIC = "sv_SE.UTF-8";
    LC_PAPER = "sv_SE.UTF-8";
    LC_TIME = "sv_SE.UTF-8";
  };
  console.keyMap = "sv-latin1";

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
        echo "║  Run: sudo nixos-rebuild switch --flake ${flakeUrl}#devbox --refresh ║"
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
