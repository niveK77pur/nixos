{
  lib,
  config,
  ...
}: let
  modname = "lightdm";
  cfg = config.display.login.${modname};
in {
  options.display.login.${modname} = {
    enable = lib.mkEnableOption "${modname}";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.displayManager.lightdm.enable = true;
  };
}
