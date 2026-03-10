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

# On a running devbox VM — update to latest config from GitHub:
sudo nixos-rebuild switch --flake github:lunjoa/nixos_devbox#devbox --refresh
```

## Architecture

- **flake.nix** — Entry point. Pins nixpkgs `nixos-25.11`, home-manager `release-25.11`, and nixos-generators. Outputs: `nixosConfigurations.devbox` and `packages.x86_64-linux.image` (OpenStack QCOW2).
- **lib/mkDevbox.nix** — Exports `devboxModules` (shared module list) and `mkConfig` (builds a nixosConfiguration).
- **modules/** — NixOS modules, each handling one concern:
  - `base.nix` — SSH, locale, system packages, nix settings
  - `vm.nix` — OpenStack/QEMU: guest agent, cloud-init, virtio drivers, grub, growpart, serial console
  - `shell.nix` — Zsh + Oh My Zsh as default shell, sources `~/.zshrc.local` for user customization
  - `vscode.nix` — `nix-ld` (required for VS Code Remote SSH on NixOS), enforced machine-level settings.json, extension list
  - `podman.nix` — Rootless Podman with Docker CLI compatibility
  - `development/node.nix` — Node.js 20
  - `development/python.nix` — Python 3.11 with pip, virtualenv, setuptools, build, wheel
- **profiles/default.nix** — Profile-level config (inotify sysctl tuning)
- **users/default.nix** — Passwordless sudo for wheel, git, skeleton files (`.zshrc`, `.zshrc.local.example`)
- **overlays/default.nix** — Package override placeholder (wired into nixpkgs via mkDevbox)
- **ansible/** — Playbooks for building, verifying, and uploading the image (all use Podman + Nix container)

## User Identity Injection

No user is baked into the image. Cloud-init creates the user at VM provisioning time from userdata. The userdata must include groups, shell, and sudo since cloud-init's `system_info.default_user` does not apply to explicit `users:` blocks.

Expected cloud-config userdata format:
```yaml
#cloud-config
users:
  - name: username
    groups: wheel, podman
    shell: /run/current-system/sw/bin/zsh
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ssh-rsa AAAA...
```

Skeleton files from `/etc/skel/` (`.zshrc`, VS Code machine settings) are copied to the user's home directory by `useradd` during cloud-init user creation.

## Conventions

- Module signatures include only the arguments actually used (e.g., `{ pkgs, ... }:` not `{ config, lib, pkgs, ... }:`)
- VS Code extensions and machine settings are defined in `modules/vscode.nix` — single source of truth for enforced editor configuration
- Shell customization happens in `~/.zshrc.local` (user-managed, not in this repo)
