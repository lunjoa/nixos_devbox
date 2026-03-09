{ config, lib, pkgs, ... }:

let
  # Import local user configuration (created by cloud-init from userdata)
  localConfig =
    if builtins.pathExists /etc/nixos/local.nix
    then import /etc/nixos/local.nix
    else { username = "developer"; sshKeys = []; };
in
{
  options.devbox = {
    username = lib.mkOption {
      type = lib.types.str;
      default = localConfig.username;
      description = "The developer's username on this devbox.";
    };

    sshKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = localConfig.sshKeys;
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

    # Allow the user to run nixos-rebuild without password
    security.sudo.extraRules = [
      {
        users = [ config.devbox.username ];
        commands = [
          {
            command = "${pkgs.nixos-rebuild}/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    # Home-manager configuration for the developer
    home-manager.users.${config.devbox.username} = { pkgs, ... }: {
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
