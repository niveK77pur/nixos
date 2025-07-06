{
  lib,
  config,
  ...
}: let
  modname = "sddm";
  cfg = config.display.login.${modname};
in {
  options.display.login.${modname} = {
    enable = lib.mkEnableOption "${modname}";
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.sddm.enable = true;
  };
}
