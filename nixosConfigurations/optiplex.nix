_: [
  {
    bootloader.systemd.enable = true;
    networking.enableWireless = false;

    users.users.server = {isNormalUser = true;};
    nix-config.enable = true;

    services.tailscale.enable = true;
  }
]
