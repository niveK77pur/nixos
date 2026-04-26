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
    restrictTailscale = lib.mkEnableOption "tailscale";
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

    (lib.mkIf cfg.restrictTailscale {
      services.tailscale = {
        enable = true;
        openFirewall = true;
      };
      networking.firewall = {
        enable = true;
        trustedInterfaces = ["tailscale0"];
        # allowPing = false;
        allowedTCPPorts = [];
        allowedUDPPorts = [];
      };
    })
  ];
}
