{
  lib,
  config,
  ...
}: let
  rootDomain = "kevinbiewesch.com";
  freshrss = rec {
    domain = "rss.${rootDomain}";
    baseUrl = "https://${domain}";
  };
  syncthing = rec {
    domain = "sync.${rootDomain}";
    guiAddress = "https://${domain}";
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
      age = {
        secrets.cloudflare.file = ../secrets/optiplex-cloudflare.age;
        identityPaths = ["/root/.ssh/agenix"];
      };
      security.acme = {
        acceptTerms = true;
        defaults = {
          email = "kevinbiewesch@yahoo.fr";
          # Configures DNS-01 challenge using cloudflare API token
          dnsProvider = "cloudflare";
          credentialFiles = {
            CLOUDFLARE_DNS_API_TOKEN_FILE = config.age.secrets.cloudflare.path;
          };
        };
        certs = {
          ${rootDomain} = {
            inherit (config.services.nginx) group;
            extraDomainNames = [
              freshrss.domain
              syncthing.domain
            ];
          };
        };
      };
      services.nginx.virtualHosts = {
        ${rootDomain} = {
          forceSSL = true;
          useACMEHost = rootDomain;
        };
        ${freshrss.domain} = {
          forceSSL = true;
          useACMEHost = rootDomain;
        };
        ${syncthing.domain} = {
          forceSSL = true;
          useACMEHost = rootDomain;
        };
      };
    }
    {
      services = {
        freshrss = {
          enable = true;
          inherit (freshrss) baseUrl;
          virtualHost = freshrss.domain;
          authType = "none"; # TODO: Authenticate via OIDC
          api.enable = true;
        };
      };
    }
    {
      services.dashy = {
        enable = true;
        virtualHost = {
          enableNginx = true;
          domain = rootDomain;
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
                {
                  title = "Syncthing";
                  icon = "${syncthing.guiAddress}/assets/img/favicon-default.png";
                  url = syncthing.guiAddress;
                }
              ];
            }
          ];
        };
      };
    }
    {
      services.syncthing = {
        enable = true;
        settings = {
          devices = {
            optiplex.id = "7PHZLSE-HMGUG2V-BL3JAMO-NGFUTFM-HFKEBSQ-SHAHSAP-RALJWPK-RG65XQS";
            supernote = {
              id = "5O5GDWG-HIR54JQ-SFAZRVF-OIGZ6BJ-R5S56TE-WOBISJL-HTXVB6G-H26A6Q2";
              addresses = lib.singleton "tcp://100.127.82.92:22000";
            };
          };
          folders = {
            SN-Note = {
              path = "~/supernote/Note";
              id = "8uvfz-kien7";
              devices = with config.services.syncthing.settings.devices; [
                optiplex.name
                supernote.name
              ];
            };
            SN-MyStyle = {
              path = "~/supernote/MyStyle";
              id = "fpehy-c1mjv";
              devices = with config.services.syncthing.settings.devices; [
                optiplex.name
                supernote.name
              ];
            };
          };
        };
      };
      services.nginx.virtualHosts.${syncthing.domain}.locations."/".proxyPass =
        "https://" + config.services.syncthing.guiAddress;
    }
  ]
