{
  lib,
  config,
  ...
}: let
  cfg = config.bootloader.systemd;
in {
  options.bootloader.systemd = {
    enable = lib.mkEnableOption "systemd";
  };

  config = lib.mkIf cfg.enable {
    # Bootloader systemd-boot.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
