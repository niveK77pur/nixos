{deviceName, ...}: let
  modname = "networking";
in {
  options.${modname} = {};

  config = {
    networking = {
      hostName = deviceName;

      # Enable networking
      wireless.iwd.enable = true;
      networkmanager = {
        enable = true;
        wifi.backend = "iwd";
      };
    };
  };
}
