{ pkgs, ... }:

let
  # Domain allowed for git remotes — Claude Code is blocked for repos
  # with remotes outside this domain (and for non-git workspaces)
  allowedGitDomain = "github.com";

  # Guard against running Claude Code outside of approved repositories.
  # Prevents accidental usage in scratch dirs, personal projects, etc.
  claudeGatekeeper = pkgs.writeShellScriptBin "claude-gatekeeper" ''
    if ! ${pkgs.git}/bin/git rev-parse --git-dir >/dev/null 2>&1; then
      echo "Not a git repository. Navigate to a project directory first." >&2
      exit 1
    fi

    remotes=$(${pkgs.git}/bin/git remote -v 2>/dev/null)
    if [ -z "$remotes" ]; then
      echo "No git remote configured. Add a remote to use Claude Code here." >&2
      exit 1
    fi

    if echo "$remotes" | ${pkgs.gnugrep}/bin/grep -vq "${allowedGitDomain}"; then
      echo "This repository has remotes outside ${allowedGitDomain}." >&2
      exit 1
    fi

    exec "$@"
  '';

  # Recommended VS Code extensions — users are prompted to install these
  recommendedExtensions = [
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
    "anthropic.claude-code"
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
    "terminal.integrated.env.linux" = {
      "GIT_EDITOR" = "code --wait";
      "GIT_SEQUENCE_EDITOR" = "code --wait";
    };
    "claudeCode.allowDangerouslySkipPermissions" = false;
    "claudeCode.respectGitIgnore" = true;
    "claudeCode.autosave" = true;
    "claudeCode.claudeProcessWrapper" = "${claudeGatekeeper}/bin/claude-gatekeeper";
  };

  # Workspace extension recommendations — VS Code prompts users to install these
  extensionsJson = builtins.toJSON {
    recommendations = recommendedExtensions;
  };

  # Claude Code managed settings — enforced system-wide, cannot be overridden
  managedSettings = builtins.toJSON {
    permissions = {
      # Hard blocks — never allowed, even with user approval
      deny = [
        # Privilege escalation
        "Bash(sudo *)"
        "Bash(su *)"
        "Bash(pkexec *)"
        "Bash(doas *)"
        "Bash(* | sudo *)"
        "Bash(* | su *)"
        "Bash(* | pkexec *)"
        "Bash(* | doas *)"
        # Dot-folders in home directory (secrets, credentials, configs)
        "Read(~/.*/**)"
        "Edit(~/.*/**)"
      ];
      # Prompt the user (not auto-approved) for access outside the project
      ask = [
        "Read(../)"
        "Edit(../)"
      ];
    };
    # Prevent users from enabling bypass/yolo mode
    disableBypassPermissionsMode = "disable";
  };
in
{
  # nix-ld is required for VS Code Remote SSH server to work on NixOS.
  # Without it, the dynamically-linked Node.js binary that VS Code downloads
  # will fail because NixOS lacks a traditional /lib/ld-linux.
  # Claude Code gatekeeper available system-wide (used by shell wrapper)
  environment.systemPackages = [ claudeGatekeeper ];

  programs.nix-ld.enable = true;

  # Machine-level VS Code settings — placed in /etc/skel so cloud-init
  # copies it to the user's home directory on creation
  environment.etc."skel/.vscode-server/data/Machine/settings.json".text = vscodeSettings;

  # Extension recommendations — VS Code prompts users to install these on first open
  environment.etc."skel/.vscode/extensions.json".text = extensionsJson;

  # Claude Code managed settings — users cannot override these
  environment.etc."claude/managed-settings.json".text = managedSettings;
}
