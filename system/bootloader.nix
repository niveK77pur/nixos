_: let
  modname = "bootloader";
in {
  options.${modname} = {};

  config = {
    # Bootloader GRUB.
    boot.loader.grub = {
      enable = true;
      device = "/dev/vda";
      useOSProber = true;
    };

    # Bootloader systemd-boot.
    # boot.loader.systemd-boot.enable = true;
    # boot.loader.efi.canTouchEfiVariables = true;

    # Kernel
    # boot.kernelPackages = pkgs.linuxPackages_latest;
  };
}
