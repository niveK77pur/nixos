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
]
