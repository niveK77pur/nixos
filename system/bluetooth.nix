{pkgs, ...}: {
  config = {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      # settings = {
      #   General = {
      #     Experimental = true; # to see battery charge
      #   }
      # };
    };

    services.blueman.enable = true;
  };
}
