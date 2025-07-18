{
  lib,
  config,
  ...
}: let
  modname = "bluetooth";
in {
  options.${modname} = {
    enable = lib.mkEnableOption "${modname}";
  };
  config = lib.mkIf config.${modname}.enable {
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
