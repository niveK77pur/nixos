_: [
  {
    bootloader.grub.enable = true;
    display.cinnamon.enable = true;
    user = {
      name = "tuxkuni";
    };
    services.qemuGuest.enable = true;
    services.spice-vdagentd.enable = true;
  }
]
