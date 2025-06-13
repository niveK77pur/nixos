{
  lib,
  config,
  ...
}: let
  cfg = config.display;
in {
  imports = [
    ./desktop
    ./login-manager
  ];

  options.display = {
    enable = lib.mkEnableOption "display";
  };

  config = lib.mkIf cfg.enable {
    display = {
      plasma.enable = lib.mkDefault true;
      login.sddm.enable = lib.mkDefault true;
    };
  };
}
