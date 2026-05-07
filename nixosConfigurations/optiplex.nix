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
    oauth2-client = {
      freshrss = {
        name = "freshrss";
        group = "freshrss_access";
      };
    };
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
      age.secrets.oauth2-freshrss.file = ../secrets/optiplex-kanidm-freshrss-oauth2.age;
      services = {
        freshrss = {
          enable = true;
          inherit (freshrss) baseUrl;
          virtualHost = freshrss.domain;
          authType = "none"; # TODO: Authenticate via OIDC
          api.enable = true;
        };
        # Specify environment variables for FreshRSS by "hooking" into the
        # module's internal `env-vars` variable.
        phpfpm.pools.${config.services.freshrss.pool}.phpEnv = {
          OIDC_ENABLED = "1";
          OIDC_PROVIDER_METADATA_URL = "https://${iam.domain}/oauth2/openid/${iam.oauth2-client.freshrss.name}/.well-known/openid-configuration";
          OIDC_CLIENT_ID = iam.oauth2-client.freshrss.name;
          OIDC_CLIENT_SECRET = "$OIDC_CLIENT_SECRET";
          # OIDC_CLIENT_CRYPTO_KEY = null;
          # OIDC_REMOTE_USER_CLAIM = null;
          OIDC_SCOPES =
            lib.concatStringsSep " "
            config.services.kanidm.provision.systems.oauth2.${iam.oauth2-client.freshrss.name}.scopeMaps.${iam.oauth2-client.freshrss.group};
          # OIDC_X_FORWARDED_HEADERS = null;
          # OIDC_SESSION_INACTIVITY_TIMEOUT = null;
          # OIDC_SESSION_MAX_DURATION = null;
          # OIDC_SESSION_TYPE = null;
        };
      };
      # Ensure the secret is available to FreshRSS; this "injects" into the
      # systemd service being created by the phpfpm pool being created by the
      # FreshRSS module.
      systemd.services."phpfpm-${config.services.freshrss.pool}".serviceConfig.EnvironmentFile = config.age.secrets.oauth2-freshrss.path;
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

          provision = {
            enable = true;
            groups.${iam.oauth2-client.freshrss.group} = {};
            systems.oauth2 = {
              ${iam.oauth2-client.freshrss.name} = {
                displayName = "FreshRSS";
                originLanding = freshrss.baseUrl;
                originUrl = "${freshrss.baseUrl}/i/oidc/";
                scopeMaps = {
                  ${iam.oauth2-client.freshrss.group} = ["openid" "email" "profile"];
                };
              };
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
