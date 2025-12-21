{
  lib,
  config,
  ...
}: let
  cfg = config.shares;
  tailscale_subnet = "100.64.0.0/10";
  nfs_root = "/srv/nfs";
in {
  options.shares = {
    enable = lib.mkEnableOption "shares";
    enableSamba = lib.mkEnableOption "samba-shares" // {default = true;};
    enableNfs = lib.mkEnableOption "nfs-shares" // {default = true;};
    shares = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = {};
      description = "Shares and folders to be exposed";
      example = ''
        {
          vinludens-videos = /home/kevin/Videos/Music_Recordings;
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf cfg.enableSamba {
        services.samba = {
          enable = true;
          openFirewall = true;
          settings = lib.mkMerge [
            {
              global = {
                "hosts allow" = "${tailscale_subnet} 127.0.0.1 localhost";
                "hosts deny" = "0.0.0.0/0";
                "security" = "user";

                "fruit:copyfile" = "yes";
                "unix extensions" = "yes";

                "server string" = "smbnix";
                "netbios name" = "smbnix";
              };
            }
            (lib.mapAttrs (_: value: {
                "path" = toString value;
                "read only" = "no";
                "veto files" = "/.direnv/";
              })
              cfg.shares)
          ];
        };
      })

      # TODO: Firewall to block NFS requests outside of tailscale?
      (lib.mkIf cfg.enableNfs {
        fileSystems = lib.mapAttrs' (name: value:
          lib.nameValuePair
          "${nfs_root}/${name}"
          {
            device = toString value;
            options = ["bind"];
          })
        cfg.shares;

        services.nfs = {
          settings = {
            nfsd = {
              # Restrict to NFSv4?
              vers3 = "off";
              vers4 = "on";
            };
          };
          server = {
            enable = true;
            exports = lib.concatLines (
              [
                "${nfs_root} ${tailscale_subnet}(rw,fsid=root)"
              ]
              ++ (
                map
                (name: "${nfs_root}/${name} ${tailscale_subnet}(rw,sync)")
                (lib.attrNames cfg.shares)
              )
            );
          };
        };

        # Restrict to NFSv4?
        environment.etc."sysconfig/nfs".text = ''
          RPCNFSDARGS="-N 2 -N 3 -U"
        '';
      })
    ]
  );
}
