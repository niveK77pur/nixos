{
  lib,
  config,
  ...
}: let
  cfg = config.bootloader.grub;
in {
  options.bootloader.grub = {
    enable = lib.mkEnableOption "bootloader.grub";
  };

  config = lib.mkIf cfg.enable {
    # Bootloader GRUB.
    boot.loader.grub = {
      enable = true;
      device = "/dev/nvme0n1p1";
      useOSProber = true;
    };
  };
}
