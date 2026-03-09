{ lib, ... }:

{
  # QEMU guest agent for OpenStack VM management
  services.qemuGuest.enable = true;

  # cloud-init for OpenStack instance provisioning
  # Handles: hostname, network config, SSH host keys, disk growth, local.nix creation
  services.cloud-init = {
    enable = true;
    network.enable = true;
  };

  # Kernel modules for QEMU/KVM virtio
  boot.initrd.availableKernelModules = [
    "virtio_net"
    "virtio_pci"
    "virtio_mmio"
    "virtio_blk"
    "virtio_scsi"
    "9p"
    "9pnet_virtio"
  ];

  boot.initrd.kernelModules = [
    "virtio_balloon"
    "virtio_console"
    "virtio_rng"
  ];

  # Boot loader — mkDefault so nixos-generators' openstack format takes precedence
  boot.loader.grub = {
    enable = lib.mkDefault true;
    device = lib.mkDefault "/dev/vda";
  };

  # Root filesystem — mkDefault so nixos-generators' openstack format takes precedence
  fileSystems."/" = {
    device = lib.mkDefault "/dev/vda1";
    fsType = lib.mkDefault "ext4";
  };

  # Grow root partition to fill allocated disk
  boot.growPartition = lib.mkDefault true;

  # Serial console for OpenStack console access
  boot.kernelParams = [ "console=ttyS0,115200" ];
  systemd.services."serial-getty@ttyS0".enable = true;
}
