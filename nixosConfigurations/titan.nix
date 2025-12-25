{
  pkgs,
  lib,
}: [
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
    shares = {
      enable = true;
      shares = {
        vinludens-videos = /home/kevin/Videos/Music_Recordings;
        vinludens-sheets = /home/kevin/Documents/VinLudens-Sheets;
      };
    };
  }
  (let
    rustdesk = pkgs.rustdesk-flutter;
  in {
    # Manual steps to restrict to tailscale(?):
    # 1. Open the RustDesk client application (here on the server)
    # 2. Under "Security" settings "Enable direct IP access"
    # 3. [Optional] Set a permanent password for unsupervised login
    #    Note that unsupervised login does not work on wayland
    services.tailscale.enable = true;
    environment.systemPackages = [rustdesk];
    services.rustdesk-server = {
      # Somehow this service must be enabled, otherwise the permissions cannot
      # be given in wayland. However, for a purely tailscale connectivity, we
      # do not need the server, hence we disable everything.
      enable = true;
      signal.enable = false;
      relay.enable = false;
    };
    # Under "Network" settings, under "ID/Relay server", sets "ID Server" to
    # `127.0.0.1`. This effectively prevents access via the RustDesk ID.
    system.activationScripts.rustdesk-server.text = ''
      ${lib.getExe rustdesk} --config rustdesk--QfiIiOikXYsVmciwiIiojIpBXYiwiIiojI5V2aiwiIx4CMuAjL3ITMiojI0N3boJye--.exe
    '';
  })
]
# vim: fdm=marker

