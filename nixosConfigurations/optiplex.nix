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

      users.users.server = {
        isNormalUser = true;
        extraGroups = ["wheel"];
      };
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
    {
      services.dashy = {
        enable = true;
        virtualHost = {
          enableNginx = true;
          inherit domain;
        };
        settings = {
          appConfig = {
            defaultOpeningMethod = "sametab";
            preventWriteToDisk = true;
            preventLocalSave = true;
            disableConfigurationForNonAdmin = true;
            disableUpdateChecks = true;
          };
          pageInfo = {
            title = "OptiPlex";
            logo = "https://avatars.githubusercontent.com/u/10981161?v=4";
            navLinks = [
              {
                title = "niveK77pur";
                path = "https://github.com/niveK77pur";
              }
              {
                title = "VinLudens GH";
                path = "https://github.com/VinLudens";
              }
            ];
          };
          sections = [
            {
              name = "Services";
              items = [
                {
                  title = "FreshRSS";
                  icon = "${freshrss.baseUrl}/favicon.ico";
                  url = freshrss.baseUrl;
                }
              ];
            }
          ];
        };
      };
    }
  ]
