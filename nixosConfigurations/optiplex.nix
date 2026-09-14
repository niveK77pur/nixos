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

  supernote-tool = inputs.supernote-tool.packages.${pkgs.stdenv.hostPlatform.system}.default;
  supernote-recursive-conversion = pkgs.callPackage ../packages/supernote-recursive-conversion/package.nix {inherit supernote-tool;};
  sn = rec {
    notePath = builtins.replaceStrings ["~"] [config.services.syncthing.dataDir] config.services.syncthing.settings.folders.SN-Note.path;
    dataDir = "/var/lib/supernote-recursive-conversion";
    cacheDir = "/var/cache/supernote-recursive-conversion";
    shaDB = "${cacheDir}/shadb";
  };
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
      services = {
        homepage-dashboard = {
          enable = true;
          settings = {
            disableIndexing = true;
            title = "OptiPlex";
            favicon = "https://avatars.githubusercontent.com/u/10981161?v=4";
            headerStyle = "boxed";
            target = "_self";
            layout."System Monitoring" = {
              initiallyCollapsed = true;
              style = "row";
              columns = 4;
            };
          };
          widgets = [
            {logo.icon = config.services.homepage-dashboard.settings.favicon;}
            {greeting.text = config.services.homepage-dashboard.settings.title;}
            {
              glances = {
                url = "http://localhost:${toString config.services.glances.port}";
                version = lib.versions.major config.services.glances.package.version;
                cpu = true;
                mem = true;
                cputemp = true;
              };
            }
          ];
          services = [
            {
              "System Monitoring" = let
                monitorSpan = 30 * 1000; # milliseconds
                refreshInterval = 1000; # milliseconds
                pointsLimit = monitorSpan / refreshInterval;
              in
                map (service: (lib.mapAttrs (name: conf:
                  lib.recursiveUpdate conf {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${toString config.services.glances.port}";
                      version = lib.versions.major config.services.glances.package.version;
                      inherit refreshInterval pointsLimit;
                    };
                  })
                service)) [
                  {Info.widget.metric = "info";}
                  {CPU.widget.metric = "cpu";}
                  {RAM.widget.metric = "memory";}
                  {Network.widget.metric = "network:enp1s0";}
                  {Temperature.widget.metric = "sensor:Package id 0";}
                  {Storage.widget.metric = "fs:/";}
                  {Processes.widget.metric = "process";}
                ];
            }
          ];
          bookmarks = [
            {
              "Home Services" = [
                {
                  FreshRSS = lib.singleton {
                    href = freshrss.baseUrl;
                    icon = "freshrss";
                  };
                }
                {
                  Syncthing = lib.singleton {
                    href = syncthing.guiAddress;
                    icon = "syncthing";
                  };
                }
              ];
            }
            {
              "My Links" = [
                {
                  niveK77pur = lib.singleton {
                    icon = "github";
                    href = "https://github.com/niveK77pur";
                  };
                }
                {
                  VinLudens = lib.singleton {
                    icon = "github";
                    href = "https://github.com/VinLudens";
                  };
                }
                {
                  NixOS = lib.singleton {
                    icon = "nixos";
                    href = "https://github.com/niveK77pur/nixos";
                  };
                }
                {
                  Home-Manager = lib.singleton {
                    icon = "nixos";
                    href = "https://github.com/niveK77pur/77configs";
                  };
                }
                {
                  NeoVim = lib.singleton {
                    icon = "neovim";
                    href = "https://github.com/niveK77pur/nvim";
                  };
                }
                {
                  VinLudens = lib.singleton {
                    icon = "youtube";
                    href = "https://youtube.com/vinludens";
                  };
                }
              ];
            }
          ];
        };
        glances.enable = true;
        nginx.virtualHosts.${rootDomain}.locations."/".proxyPass = "http://localhost:${toString config.services.homepage-dashboard.listenPort}";
      };
    }
    {
      services.syncthing = {
        enable = true;
        settings = {
          inherit (inputs.self.syncthing) devices;
          folders = lib.recursiveUpdate inputs.self.syncthing.folders {
            SN-Note-PDF = {
              path = sn.dataDir;
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
            Curriculum-Vitae = {
              path = "~/work/curriculum-vitae";
              devices = with config.services.syncthing.settings.devices; [
                optiplex.name
                tuxedo.name
              ];
            };
            Work-Applications = {
              path = "~/work/applications";
              devices = with config.services.syncthing.settings.devices; [
                optiplex.name
                tuxedo.name
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
          "--watch ${lib.escapeShellArg sn.notePath}"
          "--exts note"
          "--on-busy-update queue"
          "--debounce 1s"
          # watchexec hangs on running the command because it cannot find a
          # shell. We make our command self-sufficient with a shebang.
          "--shell none"
          "--"
          "${supernote-recursive-conversion}/bin/supernote-recursive-conversion"
          "--input-dir ${lib.escapeShellArg sn.notePath}"
          "--output-dir ${lib.escapeShellArg sn.dataDir}"
          "--shadb ${lib.escapeShellArg sn.shaDB}"
        ];
        serviceConfig = {
          Restart = "on-failure";
          Group = lib.mkIf config.services.syncthing.enable config.services.syncthing.group;
          CacheDirectory = baseNameOf sn.dataDir;
          StateDirectory = baseNameOf sn.dataDir;
          StateDirectoryMode = "2775";
        };
      };
    }
  ]
