# NixOS Devbox

NixOS flake-based configuration for developer devboxes running in OpenStack VMs. Provides a standardized development environment with enforced tooling, shell setup, and editor configuration across an organization.

VMs are provisioned by Ansible. User identity (username + SSH keys) is injected at boot via cloud-init userdata — no user accounts are baked into the image.

## What's Included

| Category | Details |
|---|---|
| **Shell** | Zsh + Oh My Zsh (robbyrussell theme), syntax highlighting, autosuggestions, fzf |
| **Editor** | VS Code Remote SSH support (nix-ld), enforced machine settings, extension recommendations |
| **Containers** | Rootless Podman with Docker CLI compatibility, podman-compose |
| **Languages** | Node.js 20, Python 3.11 (pip, virtualenv, build tools) |
| **System tools** | git, curl, wget, vim, htop, tmux, jq, yq, ripgrep, fd, tree, unzip |
| **Networking** | dig, nslookup, traceroute, telnet, ping, nmap, tcpdump, whois |
| **Diagnostics** | lsof, strace, file, openssl |

## Quick Start

### Build and upload the image

All Nix commands run inside a Podman container — the host does not need Nix installed.

```bash
# Verify configuration (flake check + build test + image build)
ansible-playbook ansible/verify.yml

# Build the OpenStack QCOW2 image
ansible-playbook ansible/build-image.yml

# Upload the image to OpenStack
ansible-playbook ansible/upload-image.yml
ansible-playbook ansible/upload-image.yml -e image_name="devbox-v2"
```

### Provision a VM

Launch a VM from the uploaded image with cloud-config userdata:

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

The `groups`, `shell`, and `sudo` fields are required — cloud-init's `system_info.default_user` does not apply to explicit `users:` blocks.

### Update a running VM

```bash
sudo nixos-rebuild switch --flake github:lunjoa/nixos_devbox#devbox --refresh
```

A background service checks for updates every 4 hours and shows a banner at login when a new version is available.

## Architecture

```
flake.nix                  Entry point — pins nixpkgs 25.11, outputs nixosConfiguration + QCOW2 image
lib/mkDevbox.nix           Shared module list and nixosConfiguration builder
modules/
  base.nix                 SSH, locale, system packages, nix settings, update checker, login banner
  vm.nix                   OpenStack/QEMU: guest agent, cloud-init, virtio, grub, growpart
  shell.nix                Zsh + Oh My Zsh, plugins, syntax highlighting, autosuggestions
  vscode.nix               nix-ld, enforced VS Code settings, extension recommendations
  podman.nix               Rootless Podman with Docker CLI alias
  development/node.nix     Node.js 20
  development/python.nix   Python 3.11 + packaging tools
profiles/default.nix       System tuning (inotify limits)
users/default.nix          Passwordless sudo, skeleton files (.zshrc, .zshrc.local.example)
overlays/default.nix       Package override placeholder
ansible/                   Playbooks for build, verify, and upload workflows
```

## Shell Customization

System Zsh configuration is managed by NixOS and should not be edited directly. To add personal customizations:

```bash
cp ~/.zshrc.local.example ~/.zshrc.local
```

`~/.zshrc.local` is sourced after Oh My Zsh loads and is not managed by this repo.

## VS Code

VS Code Remote SSH works out of the box via `nix-ld`. Machine-level settings (format on save, tab size, rulers, trailing whitespace trimming) are enforced and cannot be overridden per-user. Extension recommendations are prompted on first connect.
