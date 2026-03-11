{ lib, pkgs, ... }:

let
  flakeUrl = "github:lunjoa/nixos_devbox";

  updateCheckScript = pkgs.writeShellScript "devbox-update-check" ''
    STATE_FILE="/var/lib/devbox-update-status"

    # Get the current system's flake revision (stamped at build time via system.configurationRevision)
    CURRENT=$(/run/current-system/sw/bin/nixos-version --configuration-revision 2>/dev/null)

    # Get the remote flake's latest revision
    METADATA=$(${pkgs.nix}/bin/nix flake metadata ${flakeUrl} --json --refresh 2>/dev/null) || true
    REMOTE=$(echo "$METADATA" | ${pkgs.jq}/bin/jq -r '.revision // empty' 2>/dev/null)

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
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [ "/run/current-system/sw" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = updateCheckScript;
    };
    # Make it automatically start after a system switch
    wantedBy = [ "sysinit-reactivation.target" ];
  };

  systemd.timers.devbox-update-check = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "4h";
    };
  };

  # Login banner
  programs.zsh.loginShellInit = ''
    printf '\n'
    printf ' \033[1;36m%s\033[0m\n'                     '            ___   __     '
    printf ' \033[1;36m%s\033[0m\n'                     '     /¯\    \  \ /  ;    '
    printf ' \033[1;36m%s\033[0m\n'                     '     \  \    \  v  /     '
    printf ' \033[1;36m%s\033[0m\n'                     '  /¯¯¯   ¯¯¯¯\\   /  /\  '
    printf ' \033[1;36m%s\033[0m   %s\n'                ' ’————————————·\  \ /  ; ' ' ____  _______     ______   _____  __'
    printf ' \033[1;36m%s\033[0m   %s\n'                '      /¯¯;      \ //  /_ ' '|  _ \| ____\ \   / / __ ) / _ \ \/ /'
    printf ' \033[1;36m%s\033[0m   %s\n'                '_____/  /        ‘/     \' '| | | |  _|  \ \ / /|  _ \| | | \  / '
    printf ' \033[1;36m%s\033[0m   %s\n'                '\      /,        /  /¯¯¯¯' '| |_| | |___  \ V / | |_) | |_| /  \ '
    printf ' \033[1;36m%s\033[0m   %s\n'                ' ¯¯/  // \      /__/     ' '|____/|_____|  \_/  |____/ \___/_/\_\'
    printf ' \033[1;36m%s\033[0m\n'                     '  .  / \  \·———————————. '
    printf ' \033[1;36m%s\033[0m \033[0;37m%s\033[0m\n' '   \/  /   \\____   ___/ ' '    NixOS Development Environment'
    printf ' \033[1;36m%s\033[0m \033[0;90m%s\033[0m\n' '      /  ,  \    \  \    ' "    $(nixos-version 2>/dev/null)"
    printf ' \033[1;36m%s\033[0m \033[0;90m%s\033[0m\n' '      \_/ \__\    \_/    ' "    $(/run/current-system/sw/bin/nixos-version --configuration-revision 2>/dev/null)"
    printf '\n'

    if [ -f /var/lib/devbox-update-status ]; then
      printf '  \033[1;33m>>> \033[1;37mUpdate available\033[0m\n'
      printf '  \033[0;90m%s\033[0m\n' 'sudo nixos-rebuild switch --flake ${flakeUrl}#devbox --refresh'
      printf '\n'
    fi
  '';

  # Disable default MOTD (replaced by loginShellInit above)
  users.motd = "";
}
