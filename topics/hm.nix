{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.hm;
in {
  options.hm = {
    enable = lib.mkEnableOption "hm";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.home-manager];
  };
}
