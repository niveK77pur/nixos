{pkgs, ...}: {
  # Bootloader GRUB.
  # boot.loader.grub.enable = true;
  # boot.loader.grub.device = "/dev/nvme0n1p1";
  # boot.loader.grub.useOSProber = true;

  # Bootloader systemd-boot.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

}
