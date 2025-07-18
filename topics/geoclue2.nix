{
  lib,
  config,
  ...
}: let
  cfg = config.geoclue2;
in {
  options.geoclue2 = {
    enable = lib.mkEnableOption "geoclue2";
  };

  config = lib.mkIf cfg.enable {
    services.geoclue2 = {
      enable = true;
    };
  };
}
