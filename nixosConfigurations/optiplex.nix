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
    oauth2-proxy = rec {
      port = 4180;
      addr = "http://127.0.0.1:${toString port}";
    };
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
      age.secrets.oauth2-freshrss-cookie.file = ../secrets/optiplex-oauth2-proxy-freshrss-cookie.age;
      services = {
        freshrss = {
          enable = true;
          inherit (freshrss) baseUrl;
          virtualHost = freshrss.domain;
          authType = "http_auth";
          api.enable = true;
        };
        nginx.virtualHosts.${config.services.freshrss.virtualHost} = {
          locations = {
            "/oauth2/" = {
              proxyPass = freshrss.oauth2-proxy.addr;
              extraConfig = ''
                proxy_set_header Host                    $host;
                proxy_set_header X-Real-IP               $remote_addr;
                proxy_set_header X-Auth-Request-Redirect $request_uri;
              '';
            };
            "= /oauth2/auth" = {
              proxyPass = freshrss.oauth2-proxy.addr;
              extraConfig = ''
                proxy_set_header Host             $host;
                proxy_set_header X-Real-IP        $remote_addr;
                proxy_set_header X-Forwarded-Uri  $request_uri;
                proxy_set_header Content-Length   "";
                proxy_pass_request_body           off;
              '';
            };
            "@oauth2_signin" = {
              return = "302 /oauth2/sign_in?rd=$scheme://$host$request_uri";
            };
          };
          locations."~ ^.+?\\.php(/.*)?$".extraConfig = ''
            auth_request /oauth2/auth;
            error_page 401 = @oauth2_signin;

            auth_request_set $user $upstream_http_x_auth_request_user;
            fastcgi_param REMOTE_USER $user;
          '';
        };
      };
      systemd.services.oauth2-proxy-freshrss = rec {
        wantedBy = ["multi-user.target"];
        wants = ["network-online.target"];
        requires = ["kanidm.service"];
        after = wants ++ requires;
        serviceConfig = {
          User = "freshrss";
          Restart = "always";
          ExecStart = lib.concatStringsSep " " [
            (lib.getExe pkgs.oauth2-proxy)
            "--http-address=${freshrss.oauth2-proxy.addr}"
            "--provider=oidc"
            "--client-id=${iam.oauth2-client.freshrss.name}"
            "--client-secret-file=%d/client-secret"
            "--cookie-secret-file=%d/cookie-secret"
            "--oidc-issuer-url=https://${iam.domain}/oauth2/openid/${iam.oauth2-client.freshrss.name}"
            "--redirect-url=${config.services.kanidm.provision.systems.oauth2.${iam.oauth2-client.freshrss.name}.originUrl}"
            "--email-domain=*"
            "--scope='${lib.concatStringsSep " " config.services.kanidm.provision.systems.oauth2.${iam.oauth2-client.freshrss.name}.scopeMaps.${iam.oauth2-client.freshrss.group}}'"
            "--reverse-proxy=true"
            "--trusted-proxy-ip=127.0.0.1/32" # assuming --http-address is on 127.0.0.1
            "--trusted-proxy-ip=::1/128"
            "--whitelist-domain=${freshrss.domain}"
            "--set-xauthrequest=true"
            "--code-challenge-method=S256" # required by kanidm
          ];
          LoadCredential = [
            "client-secret:${config.age.secrets.oauth2-freshrss.path}"
            "cookie-secret:${config.age.secrets.oauth2-freshrss-cookie.path}"
          ];
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

          provision = {
            enable = true;
            groups.${iam.oauth2-client.freshrss.group} = {};
            systems.oauth2 = {
              ${iam.oauth2-client.freshrss.name} = {
                displayName = "FreshRSS";
                originLanding = freshrss.baseUrl;
                originUrl = "${freshrss.baseUrl}/oauth2/callback";
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
