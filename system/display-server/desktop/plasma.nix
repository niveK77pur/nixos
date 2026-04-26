{
  lib,
  config,
  ...
}: let
  modname = "plasma";
  cfg = config.display.${modname};
in {
  options.display.${modname} = {
    enable = lib.mkEnableOption "${modname}";
  };

  config = lib.mkIf cfg.enable {
    services = {
      xserver.enable = true;
      desktopManager.plasma6.enable = true;
    };
  };
}
