{ lib, pkgs, ... }:

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

  # MOTD
  users.motd = ''
    Welcome to DevBox — NixOS Development Environment
  '';
}
