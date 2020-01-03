{ config, lib, pkgs, ... }:
with lib; {
  imports = [
    <nixpkgs/nixos/modules/profiles/minimal.nix>
    <nixpkgs/nixos/modules/profiles/all-hardware.nix>
    <nixpkgs/nixos/modules/installer/netboot/netboot.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
    ./kexec.nix
  ];

  # Slim the package
  security.sudo.enable = false;
  services.udisks2.enable = false;
  networking.firewall.logRefusedConnections = false;

  # User stuff
  services.mingetty.autologinUser = "root";
  users.users.root.initialHashedPassword = "";

  # Packages
  environment.systemPackages = with pkgs; [ gnufdisk tmux vim xfsprogs.bin ];

  # Kernel stuff
  hardware.enableRedistributableFirmware = true;
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "ehci_pci"
    "ahci"
    "virtio_pci"
    "sd_mod"
    "sr_mod"
    "virtio_blk"
  ];

  # Filesystems
  boot.supportedFilesystems = [ "vfat" "xfs" "btrfs" ];

  # Enable ssh
  systemd.services.sshd.wantedBy = mkForce [ "multi-user.target" ];

  # Hostname
  networking.hostName = "emergency";

  # Perform better with low-memory
  environment.variables.GC_INITIAL_HEAP_SIZE = "1M";
  boot.kernel.sysctl."vm.overcommit_memory" = "1";

  # nix stuff
  nix = {
    buildCores = 0;
    gc.automatic = false;
  };
  nixpkgs.config.allowUnfree = true;

  services.openssh = {
    enable = true;
    permitRootLogin = "without-password";
    hostKeys = [ ]; # We will take the keys of the old system
  };
}
