{
  pkgs,
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
      displayManager.sddm.enable = true;
      desktopManager.plasma6.enable = true;
    };
    environment.systemPackages = lib.lists.optional config.topics.pass.enable pkgs.plasma-pass;
  };
}
