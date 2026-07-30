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
    hardware.printers.ensurePrinters = [
      {
        name = "laserjet";
        location = "Home";
        deviceUri = "ipp://10.0.0.100:631/ipp";
        model = "HP/hp-color_laserjet_mfp_e47528-ps.ppd.gz";
        ppdOptions = {
          PageSize = "A4";
        };
      }
    ];
  };
}
