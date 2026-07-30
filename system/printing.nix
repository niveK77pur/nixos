{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.printing;
in {
  options.printing = {
    enable = lib.mkEnableOption "printing";
  };

  config = lib.mkIf cfg.enable {
    services.printing = {
      enable = true;
      drivers = [
        pkgs.hplip
      ];
    };
    programs.system-config-printer.enable = true;
    # hardware.printers.ensurePrinters = [
    #   {
    #     name = "laserjet";
    #     deviceUri = "http://10.0.0.100";
    #     model = "";
    #     ppdOptions = {
    #       PageSize = "A4";
    #     };
    #   }
    # ];
  };
}
