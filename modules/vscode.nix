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
    "extensions.autoUpdate" = false;
    "extensions.autoCheckUpdates" = false;
  };

  # Workspace extension recommendations — VS Code prompts users to install these
  extensionsJson = builtins.toJSON {
    recommendations = enforcedExtensions;
  };
in
{
  # nix-ld is required for VS Code Remote SSH server to work on NixOS.
  # Without it, the dynamically-linked Node.js binary that VS Code downloads
  # will fail because NixOS lacks a traditional /lib/ld-linux.
  programs.nix-ld.enable = true;

  # Machine-level VS Code settings — placed in /etc/skel so cloud-init
  # copies it to the user's home directory on creation
  environment.etc."skel/.vscode-server/data/Machine/settings.json".text = vscodeSettings;

  # Extension recommendations — VS Code prompts users to install these on first open
  environment.etc."skel/.vscode/extensions.json".text = extensionsJson;
}
