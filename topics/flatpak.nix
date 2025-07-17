{
  lib,
  config,
  ...
}: let
  cfg = config.flatpak;
in {
  options.flatpak = {
    enable = lib.mkEnableOption "flatpak";
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;
  };
}
