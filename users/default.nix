{ config, lib, pkgs, ... }:

{
  options.devbox = {
    username = lib.mkOption {
      type = lib.types.str;
      default = "developer";
      description = "The developer's username on this devbox.";
    };

    sshKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "SSH public keys for the developer.";
    };
  };

  config = {
    users.users.${config.devbox.username} = {
      isNormalUser = true;
      home = "/home/${config.devbox.username}";
      shell = pkgs.zsh;
      extraGroups = [ "wheel" "podman" ];
      openssh.authorizedKeys.keys = config.devbox.sshKeys;
    };

    # Passwordless sudo — this is a single-user development VM
    security.sudo.extraRules = [
      {
        users = [ config.devbox.username ];
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    # Home-manager configuration for the developer
    home-manager.users.${config.devbox.username} = { ... }: {
      home.stateVersion = "25.11";
      home.homeDirectory = "/home/${config.devbox.username}";

      programs.git.enable = true;

      # Example file for shell customization
      home.file.".zshrc.local.example" = {
        text = ''
          # ~/.zshrc.local — Your personal Zsh customizations
          # Rename this file to ~/.zshrc.local to activate.
          # It is sourced after Oh My Zsh loads.
          #
          # Examples:
          # alias ll='ls -la'
          # export EDITOR=vim
          # export PATH="$HOME/bin:$PATH"
        '';
      };
    };
  };
}
