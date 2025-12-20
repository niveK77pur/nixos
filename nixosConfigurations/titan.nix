_: [
  {
    user = {
      name = "kevin";
    };
    hardware.keyboard.qmk = {
      enable = true;
      keychronSupport = true;
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
]
