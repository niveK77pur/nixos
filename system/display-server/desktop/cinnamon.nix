{
  lib,
  config,
  ...
}: let
  modname = "cinnamon";
  cfg = config.display.${modname};
in {
  options.display.${modname} = {
    enable = lib.mkEnableOption "${modname}";
  };

  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable = true;
      desktopManager.cinnamon.enable = true;
    };
  };
}
