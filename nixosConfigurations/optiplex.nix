_: [
  {
    bootloader.systemd.enable = true;
    networking = {
      enableWireless = false;
      restrictTailscale = true;
    };

    users.users.server = {isNormalUser = true;};
    nix-config.enable = true;

    services.tailscale.enable = true;
  }
]
