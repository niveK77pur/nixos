{
  lib,
  config,
  ...
}: let
  modname = "hyprland";
  cfg = config.display.${modname};
in {
  options.display.${modname} = {
    enable = lib.mkEnableOption "${modname}";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      hyprland = {
        enable = true;
        xwayland.enable = true;
      };
    };
    # enable screen-sharing on wlroots-based compositor
    xdg.portal.wlr.enable = true;
  };
}
