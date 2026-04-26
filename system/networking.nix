{
  config,
  lib,
  ...
}: let
  modname = "networking";
  cfg = config.${modname};
in {
  options.${modname} = {
    enableWireless = lib.mkEnableOption "networking wireless" // {default = true;};
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enableWireless {
      networking = {
        wireless.iwd.enable = true;
        networkmanager = {
          enable = true;
          wifi.backend = "iwd";
        };
      };
    })
  ];
}
