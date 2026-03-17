{ pkgs, ... }:

{
  # Set Zsh as default shell for all users
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # Oh My Zsh
  programs.zsh.ohMyZsh = {
    enable = true;
    theme = "robbyrussell";
    plugins = [
      "git"
      "npm"
      "python"
      "ssh-agent"
      "history"
      "z"
      "podman"
      "systemd"
    ];
  };

  # Zsh completions
  programs.zsh.enableCompletion = true;

  # Disable the new-user wizard — system zshrc handles all config
  environment.etc."zshenv.local".text = ''
    # Disable Zsh new-user setup wizard (zsh-newuser-install)
    zsh-newuser-install() { :; }
  '';

  # Source user-local customizations at the end of zshrc
  programs.zsh.interactiveShellInit = ''
    # Wrap claude CLI with the gatekeeper (same restrictions as VS Code extension)
    claude() { claude-gatekeeper command claude "$@"; }

    # Source user-local customizations if they exist
    if [[ -f "$HOME/.zshrc.local" ]]; then
      source "$HOME/.zshrc.local"
    fi
  '';

  # Shell enhancement tools
  environment.systemPackages = with pkgs; [
    zsh-autosuggestions
    zsh-syntax-highlighting
    fzf
  ];

  # Enable zsh plugins system-wide
  programs.zsh.syntaxHighlighting.enable = true;
  programs.zsh.autosuggestions.enable = true;
}
