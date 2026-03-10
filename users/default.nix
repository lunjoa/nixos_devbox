{ ... }:

{
  # User is created by cloud-init from OpenStack userdata (username + SSH keys).
  # Groups, shell, and sudo are configured via cloud-init system_info in vm.nix.

  # Passwordless sudo for wheel group — this is a single-user development VM
  security.sudo.wheelNeedsPassword = false;

  # Git available system-wide
  programs.git.enable = true;

  # Skeleton files — copied to new user's home directory on creation
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
