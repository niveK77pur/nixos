{
  lib,
  config,
  pkgs,
  ...
}: let
  rootDomain = "kevinbiewesch.com";
  freshrss = rec {
    domain = "rss.${rootDomain}";
    baseUrl = "https://${domain}";
  };
  iam = rec {
    domain = "idm.${rootDomain}";
    origin = "https://${domain}";
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
            ];
          };
          ${iam.domain} = {
            inherit (config.services.nginx) group;
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
                  title = "Kanidm";
                  icon = "${iam.origin}/pkg/img/favicon.png";
                  url = iam.origin;
                }
              ];
            }
          ];
        };
      };
    }
    {
      # Allow reading of the ACME certificate files by server
      users.users.kanidm.extraGroups = [config.services.nginx.group];

      services = {
        kanidm = {
          package = pkgs.kanidm_1_10;

          server = {
            enable = true;
            settings = {
              inherit (iam) domain origin;
              online_backup.versions = 10;
              tls_chain = "/var/lib/acme/${iam.domain}/fullchain.pem";
              tls_key = "/var/lib/acme/${iam.domain}/key.pem";
            };
          };

          client = {
            enable = true;
            settings = {
              uri = iam.origin;
            };
          };
        };

        nginx.virtualHosts.${iam.domain} = {
          forceSSL = true;
          useACMEHost = iam.domain;
          locations."/".proxyPass = "https://${config.services.kanidm.server.settings.bindaddress}";
        };
      };
    }
  ]
