_: [
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
          # Only allow tailscale hosts
          "hosts allow" = "100.64.0.0/10 127.0.0.1 localhost";
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
  #  }}}1
]
# vim: fdm=marker

