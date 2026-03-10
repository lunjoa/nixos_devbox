{ ... }:

{
  # User is created by cloud-init from OpenStack userdata.
  # Userdata must include: name, groups, shell, sudo, ssh_authorized_keys.

  # Passwordless sudo for wheel group — this is a single-user development VM
  security.sudo.wheelNeedsPassword = false;

  # Git available system-wide
  programs.git.enable = true;

  # Skeleton files — copied to new user's home directory on creation
  environment.etc."skel/.zshrc".text = ''
    # Managed by NixOS — system config is in /etc/zshrc
    # Add personal customizations to ~/.zshrc.local
  '';

  environment.etc."skel/.zshrc.local.example".text = ''
    # ~/.zshrc.local — Your personal Zsh customizations
    # Rename this file to ~/.zshrc.local to activate.
    # It is sourced after Oh My Zsh loads.
    #
    # Examples:
    # alias ll='ls -la'
    # export EDITOR=vim
    # export PATH="$HOME/bin:$PATH"
  '';
}
