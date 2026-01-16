_: {
  config = {
    # Set your time zone.
    time.timeZone = "Europe/Luxembourg";

    # Select internationalisation properties.
    i18n.defaultLocale = "en_GB.UTF-8";

    # Configure console keymap
    console.keyMap = "fr_CH";

    # Enable touchpad support (enabled default in most desktopManager).
    # services.xserver.libinput.enable = true;

    # # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    boot.tmp.cleanOnBoot = true;

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    # programs.mtr.enable = true;
    # programs.gnupg.agent = {
    #   enable = true;
    #   enableSSHSupport = true;
    # };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "23.11"; # Did you read the comment?

    system.autoUpgrade = {
      enable = true;
      allowReboot = false;
      channel = "https://channels.nixos.org/nixos-unstable";
    };
  };
}
