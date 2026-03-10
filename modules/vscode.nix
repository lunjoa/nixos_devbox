{ pkgs, ... }:

let
  # Enforced VS Code extensions — installed for all developers
  enforcedExtensions = [
    "ms-python.python"
    "ms-python.vscode-pylance"
    "dbaeumer.vscode-eslint"
    "esbenp.prettier-vscode"
    "redhat.vscode-yaml"
    "redhat.ansible"
    "eamodio.gitlens"
    "hediet.vscode-drawio"
    "davidanson.vscode-markdownlint"
    "jnoortheen.nix-ide"
    "tomoki1207.pdf"
    "shopify.ruby-lsp"
  ];

  # Machine-level VS Code settings (read-only, cannot be overridden by users)
  vscodeSettings = builtins.toJSON {
    "editor.formatOnSave" = true;
    "editor.tabSize" = 2;
    "editor.rulers" = [ 80 120 ];
    "files.trimTrailingWhitespace" = true;
    "files.insertFinalNewline" = true;
    "python.defaultInterpreterPath" = "${pkgs.python311}/bin/python";
    "remote.SSH.defaultExtensions" = enforcedExtensions;
    "extensions.autoUpdate" = false;
    "extensions.autoCheckUpdates" = false;
  };
in
{
  # nix-ld is required for VS Code Remote SSH server to work on NixOS.
  # Without it, the dynamically-linked Node.js binary that VS Code downloads
  # will fail because NixOS lacks a traditional /lib/ld-linux.
  programs.nix-ld.enable = true;

  # Machine-level VS Code settings — source file for home-manager to link
  environment.etc."devbox/vscode-machine-settings.json" = {
    text = vscodeSettings;
    mode = "0444";
  };
}
