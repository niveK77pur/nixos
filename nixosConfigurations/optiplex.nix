{
  inputs,
  pkgs,
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

  supernote-tool = pkgs.callPackage ../packages/supernote-tool.nix {};
  supernote-recursive-conversion = pkgs.callPackage ../packages/supernote-recursive-conversion/package.nix {inherit supernote-tool;};
  snNotePath = builtins.replaceStrings ["~"] [config.services.syncthing.dataDir] config.services.syncthing.settings.folders.SN-Note.path;
  snDataDir = "/var/lib/supernote-recursive-conversion";
  snCacheDir = "/var/cache/supernote-recursive-conversion";
  snOutDir = snDataDir;
  snShaDB = "${snCacheDir}/shadb";
in
  lib.mkMerge [
    {
      bootloader.systemd.enable = true;
      networking = {
        enableWireless = false;
        restrictTailscale = true;
      };

      programs.fish.enable = true;
      users = {
        defaultUserShell = pkgs.fish;
        users.server = {
          isNormalUser = true;
          extraGroups = ["wheel"];
        };
      };
      nix-config.enable = true;
      base.withComma = true;
    }
    {
      backup = {
        enable = true;
        locations = {
          freshrss = {
            path = config.services.freshrss.dataDir;
            destinations = {
              local = "/var/lib/borgbackup/freshrss";
            };
            snapperOpts.TIMELINE_CREATE = true;
            borgOpts.encryption.mode = "none";
          };
          syncthing = {
            path = config.services.syncthing.dataDir;
            destinations = {
              local = "/var/lib/borgbackup/syncthing";
            };
            snapperOpts.TIMELINE_CREATE = true;
            borgOpts.encryption.mode = "none";
          };
        };
      };
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
          inherit (inputs.self.syncthing) devices;
          folders = lib.recursiveUpdate inputs.self.syncthing.folders {
            SN-Note-PDF = {
              path = snOutDir;
              type = "sendonly";
              devices = with config.services.syncthing.settings.devices; [
                optiplex.name
                tuxedo.name
                titan.name
              ];
            };
            SN-Note = {
              path = "~/supernote/Note";
              devices = with config.services.syncthing.settings.devices; [
                optiplex.name
                supernote.name
              ];
            };
            SN-MyStyle = {
              path = "~/supernote/MyStyle";
              devices = with config.services.syncthing.settings.devices; [
                optiplex.name
                supernote.name
              ];
            };
            VinLudens-Sheets = {
              path = "~/vinludens/sheets";
              devices = with config.services.syncthing.settings.devices; [
                optiplex.name
                tuxedo.name
                titan.name
              ];
            };
            Aegis = {
              path = "~/aegis";
              devices = with config.services.syncthing.settings.devices; [
                optiplex.name
                zenfone.name
              ];
            };
          };
        };
      };
      services.nginx.virtualHosts.${syncthing.domain}.locations."/".proxyPass =
        "https://" + config.services.syncthing.guiAddress;
    }
    {
      systemd.services.supernote-recursive-conversion = {
        description = "Map supernote .note files to PDF";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        script = lib.concatStringsSep " " [
          (lib.getExe pkgs.watchexec)
          "--watch ${lib.escapeShellArg snNotePath}"
          "--exts note"
          "--on-busy-update queue"
          "--debounce 1s"
          # watchexec hangs on running the command because it cannot find a
          # shell. We make our command self-sufficient with a shebang.
          "--shell none"
          "--"
          "${supernote-recursive-conversion}/bin/supernote-recursive-conversion"
          "--input-dir ${lib.escapeShellArg snNotePath}"
          "--output-dir ${lib.escapeShellArg snOutDir}"
          "--shadb ${lib.escapeShellArg snShaDB}"
        ];
        serviceConfig = {
          Restart = "on-failure";
          Group = lib.mkIf config.services.syncthing.enable config.services.syncthing.group;
          CacheDirectory = baseNameOf snDataDir;
          StateDirectory = baseNameOf snDataDir;
          StateDirectoryMode = "2775";
        };
      };
    }
  ]
