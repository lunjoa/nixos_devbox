# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NixOS flake-based configuration for developer devboxes running in OpenStack VMs. Provides a standardized development environment with enforced tooling across an organization. VMs are provisioned by Ansible, with cloud-init injecting per-developer identity (username + SSH keys) via userdata.

## Key Commands

All Nix commands run inside a Podman container (host does not have Nix installed).

```bash
# Verify configuration (flake check + build test + image build)
ansible-playbook ansible/verify.yml

# Build the OpenStack QCOW2 image
ansible-playbook ansible/build-image.yml

# Upload the image to OpenStack
ansible-playbook ansible/upload-image.yml
ansible-playbook ansible/upload-image.yml -e image_name="devbox-v2"

# On a running devbox VM (has Nix):
sudo nixos-rebuild switch --flake github:org/nixos_devbox#devbox
```

## Architecture

- **flake.nix** — Entry point. Pins nixpkgs `nixos-25.11`, home-manager `release-25.11`, and nixos-generators. Outputs: `nixosConfigurations.devbox` and `packages.x86_64-linux.image` (OpenStack QCOW2).
- **lib/mkDevbox.nix** — Exports `devboxModules` (shared module list), `mkConfig` (builds a nixosConfiguration), and `flakeUrl` (single source of truth for the remote flake URL).
- **modules/** — NixOS modules, each handling one concern:
  - `base.nix` — SSH, locale, system packages, nix settings, update checker (systemd timer + login banner)
  - `vm.nix` — OpenStack/QEMU: guest agent, cloud-init, virtio drivers, grub, growpart, serial console
  - `shell.nix` — Zsh + Oh My Zsh as default shell, sources `~/.zshrc.local` for user customization
  - `vscode.nix` — `nix-ld` (required for VS Code Remote SSH on NixOS), enforced machine-level settings.json, extension list
  - `podman.nix` — Rootless Podman with Docker CLI compatibility
  - `first-boot.nix` — One-shot systemd service: waits for cloud-init, then runs `nixos-rebuild switch` from remote flake
  - `development/node.nix` — Node.js 20
  - `development/python.nix` — Python 3.11 with pip, virtualenv, setuptools, build, wheel
- **profiles/default.nix** — Profile-level config (inotify sysctl tuning)
- **users/default.nix** — Defines `devbox.username` and `devbox.sshKeys` NixOS options, imports `/etc/nixos/local.nix` (written by cloud-init), creates the user + home-manager config
- **overlays/default.nix** — Package override placeholder (wired into nixpkgs via mkDevbox)
- **ansible/** — Playbooks for building, verifying, and uploading the image (all use Podman + Nix container)

## User Identity Injection

Per-developer config is **not** stored in this repo. Instead:
1. Ansible creates the OpenStack VM with cloud-init userdata
2. cloud-init writes `/etc/nixos/local.nix` with `{ username, sshKeys }`
3. `users/default.nix` imports that file to configure the user

## Conventions

- Module signatures include only the arguments actually used (e.g., `{ pkgs, ... }:` not `{ config, lib, pkgs, ... }:`)
- The remote flake URL is defined once in `lib/mkDevbox.nix` and passed to modules via `specialArgs`
- VS Code extensions and machine settings are defined in `modules/vscode.nix` — single source of truth for enforced editor configuration
- Shell customization happens in `~/.zshrc.local` (user-managed, not in this repo)
