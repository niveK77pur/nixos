{lib, ...}: let
  domain = "optiplex";
  freshrss = rec {
    port = 8080;
    baseUrl = "http://${domain}:${toString port}";
  };
in
  lib.mkMerge [
    {
      bootloader.systemd.enable = true;
      networking = {
        enableWireless = false;
        restrictTailscale = true;
      };

      users.users.server = {isNormalUser = true;};
      nix-config.enable = true;
    }
    {
      services = {
        freshrss = {
          enable = true;
          inherit (freshrss) baseUrl;
          authType = "none"; # TODO: Authenticate via OIDC
          api.enable = true;
        };
        # TODO: Swap out `freshrss` with `config.services.freshrss.virtualHost`
        nginx.virtualHosts."freshrss" = {
          serverAliases = [domain];
          listen = [
            {
              addr = "0.0.0.0";
              inherit (freshrss) port;
            }
          ];
        };
      };
    }
  ]
