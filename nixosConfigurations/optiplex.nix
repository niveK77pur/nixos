{lib, ...}:
lib.mkMerge [
  {
    bootloader.systemd.enable = true;
    networking = {
      enableWireless = false;
      restrictTailscale = true;
    };

    users.users.server = {isNormalUser = true;};
    nix-config.enable = true;
  }
  {
    services.freshrss = {
      enable = true;
      baseUrl = "http://optiplex";
      authType = "none"; # TODO: Authenticate via OIDC
      api.enable = true;
    };
  }
]
