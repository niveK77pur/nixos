_: let
  tailscale_subnet = "100.64.0.0/10";
in [
  {
    user = {
      name = "kevin";
    };
    bootloader.systemd.enable = true;
    display = {
      enable = true;
      hyprland.enable = true;
    };
    audio = {
      enableTools = true;
      pipewire.enable = true;
      jack.enable = true;
    };
    gpu.amd.enable = true;
    hm.enable = true;
    geoclue2.enable = true;
    bluetooth.enable = true;
    gaming.enable = true;
  }
  {
    # Fix issue where launcher.keychron.com cannot connect to the keyboard for
    # configuration
    hardware.keyboard.qmk = {
      enable = true;
      keychronSupport = true;
    };
  }
  {
    services.tailscale.enable = true;
  }
  # Configure SAMBA for sharing files {{{1
  {
    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "hosts allow" = "${tailscale_subnet} 127.0.0.1 localhost";
          "hosts deny" = "0.0.0.0/0";
          "security" = "user";

          "fruit:copyfile" = "yes";
          "unix extensions" = "yes";

          "server string" = "smbnix";
          "netbios name" = "smbnix";
        };
        vinludens-videos = {
          "path" = "/home/kevin/Videos/Music_Recordings";
          "read only" = "no";
          "veto files" = "/.direnv/";
        };
      };
    };
  }
  # Configure NFS for sharing files {{{1
  (let
    nfs_root = "/srv/nfs";
  in {
    # TODO: Firewall to block NFS requests outside of tailscale?
    fileSystems = {
      "${nfs_root}/vinludens-videos" = {
        device = "/home/kevin/Videos/Music_Recordings";
        options = ["bind"];
      };
    };
    # Restrict to NFSv4?
    environment.etc."sysconfig/nfs".text = ''
      RPCNFSDARGS="-N 2 -N 3 -U"
    '';
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
        exports = ''
          ${nfs_root} ${tailscale_subnet}(rw,fsid=root)
          ${nfs_root}/vinludens-videos ${tailscale_subnet}(rw,sync)
        '';
      };
    };
  })
  #  }}}1
]
# vim: fdm=marker

