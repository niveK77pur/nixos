{
  deviceName,
  lib,
  ...
}: let
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

      firewall = lib.mkMerge [
        # TODO: only add if KDE Connect is enabled in NixOS
        (lib.mkIf true {
          allowedTCPPortRanges = [
            {
              from = 1714;
              to = 1764;
            } # KDE Connect
          ];
          allowedUDPPortRanges = [
            {
              from = 1714;
              to = 1764;
            } # KDE Connect
          ];
        })
      ];
    };
  };
}
