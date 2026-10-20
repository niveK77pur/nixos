{
  inputs,
  pkgs,
  lib,
  config,
  options,
  ...
}: let
  mydomain = {
    root = "kevinbiewesch.com";
    records = builtins.mapAttrs (name: value:
      rec {
        domain = "${value.name or name}.${mydomain.root}";
        url = "https://${domain}";
        homepage-icon = name;
        homepage-label = lib.strings.toSentenceCase name;
      }
      // value) {
      freshrss.name = "rss";
      syncthing.name = "sync";
      bookmarks.homepage-icon = "readeck";
      tasks.homepage-icon = "vikunja";
      files = {
        homepage-icon = "copyparty";
        url = "http://optiplex:3923";
      };
    };
  };

  supernote-tool = inputs.supernote-tool.packages.${pkgs.stdenv.hostPlatform.system}.default;
  supernote-recursive-conversion = pkgs.callPackage ../packages/supernote-recursive-conversion/package.nix {inherit supernote-tool;};
  sn = rec {
    notePath = builtins.replaceStrings ["~"] [config.services.syncthing.dataDir] config.services.syncthing.settings.folders.SN-Note.path;
    dataDir = "/var/lib/supernote-recursive-conversion";
    cacheDir = "/var/cache/supernote-recursive-conversion";
    shaDB = "${cacheDir}/shadb";
  };
in {
  imports = [inputs.copyparty.nixosModules.default];
  config = lib.mkMerge [
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
            snapperOpts = {
              TIMELINE_CREATE = true;
              TIMELINE_CLEANUP = true;
            };
            borgOpts = {
              encryption.mode = "none";
              prune.keep = {
                monthly = 6;
                weekly = 7;
                daily = 10;
              };
            };
          };
          syncthing = {
            path = config.services.syncthing.dataDir;
            destinations = {
              local = "/var/lib/borgbackup/syncthing";
            };
            snapperOpts = {
              TIMELINE_CREATE = true;
              TIMELINE_CLEANUP = true;
              TIMELINE_LIMIT_HOURLY = 7 * 24;
              TIMELINE_LIMIT_DAILY = 31;
              TIMELINE_LIMIT_WEEKLY = 10;
              TIMELINE_LIMIT_MONTHLY = 2 * 12;
            };
            borgOpts = {
              encryption.mode = "none";
              prune.keep = {
                daily = 31;
                weekly = 12;
                monthly = 24;
                yearly = 10;
              };
            };
          };
        };
      };
    }
    (let
      records-domains = builtins.catAttrs "domain" (builtins.attrValues mydomain.records);
    in {
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
          ${mydomain.root} = {
            inherit (config.services.nginx) group;
            extraDomainNames = records-domains;
          };
        };
      };
      services.nginx.virtualHosts = builtins.listToAttrs (map
        (domain:
          lib.nameValuePair domain {
            forceSSL = true;
            useACMEHost = mydomain.root;
          })
        ([mydomain.root] ++ records-domains));
    })
    {
      services = {
        freshrss = {
          enable = true;
          baseUrl = mydomain.records.freshrss.url;
          virtualHost = mydomain.records.freshrss.domain;
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
              "Home Services" = map (record: {
                ${record.homepage-label} = lib.singleton {
                  href = record.url;
                  icon = record.homepage-icon;
                };
              }) (lib.attrValues mydomain.records);
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
        nginx.virtualHosts.${mydomain.root}.locations."/".proxyPass = "http://localhost:${toString config.services.homepage-dashboard.listenPort}";
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
      services.nginx.virtualHosts.${mydomain.records.syncthing.domain}.locations."/".proxyPass =
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
    {
      services = {
        readeck = {
          enable = true;
          settings = {
            server = {
              host = "127.0.0.1";
              port = 8000;
              allowed_hosts = [mydomain.records.bookmarks.domain];
              trusted_proxies = ["127.0.0.1"];
            };
          };
        };
        nginx.virtualHosts.${mydomain.records.bookmarks.domain}.locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.readeck.settings.server.port}";
          extraConfig = ''
            proxy_set_header  X-Real-IP         $remote_addr;
            proxy_set_header  Host              $host;
            proxy_set_header  X-Forwarded-For   $proxy_add_x_forwarded_for;
            proxy_set_header  X-Forwarded-Proto $scheme;
            proxy_redirect off;
            proxy_buffering off;
            client_max_body_size 50M;
          '';
        };
      };
    }
    {
      services = {
        vikunja = {
          enable = true;
          frontendScheme = "http";
          frontendHostname = mydomain.records.tasks.domain;
          settings = {
            service = {
              enableemailreminders = false;
              # Registration must be enabled to create first user
              enableregistration = false;
            };
            defaultsettings = {
              week_start = 1; # Monday
            };
          };
        };
        nginx.virtualHosts.${mydomain.records.tasks.domain}.locations."/" = {
          proxyPass = "http://localhost:${toString config.services.vikunja.port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
          extraConfig = ''
            client_max_body_size 5000M;
            proxy_read_timeout   600s;
            proxy_send_timeout   600s;
            send_timeout         600s;
          '';
        };
      };
    }
    {
      age.secrets.copyparty-admin-password = {
        file = ../secrets/copyparty-admin-password.age;
        owner = config.services.copyparty.user;
        group = config.services.copyparty.group;
      };
      services.copyparty = {
        enable = true;
        settings =
          options.services.copyparty.settings.default
          // {
            i = "0.0.0.0"; # TODO: Put behind nginx
          };
        accounts.admin.passwordFile = config.age.secrets.copyparty-admin-password.path;
        volumes = {
          "/copyparty" = {
            path = options.services.copyparty.volumes.default."/".path;
            access = {
              r = "*";
              A = "admin";
            };
          };
          "/syncthing" = {
            path = config.services.syncthing.dataDir;
            access = {
              r = "*";
              A = "admin";
            };
          };
          "/syncthing/supernote-pdf" = {
            # WARN: This is a read-only folder managed by the corresponding service
            path = sn.dataDir;
            access.r = "*";
          };
        };
      };
      systemd.services.copyparty-acl = let
        cpuser = config.services.copyparty.user;
        copyparty-nix-paths = pkgs.writeTextFile {
          name = "copyparty-nix-paths";
          text = lib.pipe config.services.copyparty.volumes [
            lib.attrValues
            (builtins.catAttrs "path")
            (lib.concatStringsSep "\n")
          ];
        };
        setfacl = "${pkgs.acl}/bin/setfacl";
        findSetfacl = let
          prunePaths = [
            ".snapshots"
            ".borgbackup-snapshots"
            ".direnv"
          ];
          findPruneExpr = lib.pipe prunePaths [
            (map (e: "-name ${lib.escapeShellArg e}"))
            (lib.concatStringsSep " -o ")
          ];
        in
          lib.getExe (pkgs.writeShellApplication {
            name = "find-setfacl";
            text = ''
              path="$1"
              shift 1
              find "$path" \( -type l -o ${findPruneExpr} \) -prune -o "$@"
            '';
            meta.longDescription = ''
              The basic `setfacl -R` fails on the btrfs subvolume boundaries that
              may appear as a result of the `.snapshots` folders used for btrfs
              snapshots.

              This alternative command uses `find` to mimic the recursion, while
              also allowing to specify an exclusion list of folders (i.e.
              snapshots folders). This provides better granularity over the
              recursion.
            '';
          });
      in {
        description = "Set up ACL for copyparty volumes";
        wantedBy = ["copyparty.service"];
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          StateDirectory = "copyparty-acl";
        };
        script = ''
          stateFile="$STATE_DIRECTORY/paths"
          [ ! -f "$stateFile" ] && touch "$stateFile"

          set -x

          for path in $(comm -23 <(sort "$stateFile") <(sort "${copyparty-nix-paths}")); do
            echo "Removing ACL for unmanaged $path"
            # Remove ACL on files and folders
            ${findSetfacl} "$path" -exec ${setfacl} -x u:${cpuser} {} +
            # Remove default ACL on folders
            ${findSetfacl} "$path" -type d -exec ${setfacl} -x d:u:${cpuser} {} +
          done

          # Remove cleaned up paths from statefile
          tmpState="$(mktemp "$STATE_DIRECTORY/paths.XXXXXX")"
          comm -12 --output-delimiter="" <(sort "$stateFile") <(sort "${copyparty-nix-paths}") > "$tmpState"
          mv "$tmpState" "$stateFile"

          # NOTE: We apply `rwx` ACL to make life simple. Trust and
          # responsibility is delegated to copyparty for managing the desired
          # access to the various files and folders.
          for path in $(comm -13 <(sort "$stateFile") <(sort "${copyparty-nix-paths}")); do
            echo "Applying ACL for added $path"
            # Apply recursively to all files
            ${findSetfacl} "$path" -exec ${setfacl} -m u:${cpuser}:rwX {} +
            # Apply default ACL on folders
            ${findSetfacl} "$path" -type d -exec ${setfacl} -m d:u:${cpuser}:rwx {} +
          done

          # The effective mask may be reset, preventing access
          echo "Refreshing ACL on root for paths:"
          cat "${copyparty-nix-paths}"
          ${setfacl} -m u:${cpuser}:rwX - < "${copyparty-nix-paths}"

          # Update with final state
          cp "${copyparty-nix-paths}" "$stateFile"
        '';
      };
    }
  ];
}
