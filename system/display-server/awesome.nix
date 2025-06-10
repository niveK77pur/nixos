{
  pkgs,
  lib,
  config,
  ...
}: let
  modname = "awesome";
  cfg = config.display.${modname};
in {
  options.display.${modname} = {
    enable = lib.mkEnableOption "${modname}";
  };

  config = lib.mkIf cfg.enable {
    services = {
      # https://nixos.wiki/wiki/Awesome
      xserver = {
        enable = true;
        displayManager = {
          sddm.enable = true;
          defaultSession = "none+awesome";
        };
        windowManager.awesome = {
          enable = true;
          luaModules = with pkgs.luaPackages; [
            luarocks # is the package manager for Lua modules
            luadbi-mysql # Database abstraction layer
          ];
        };
      };
      picom.enable = true;
    };
  };
}
