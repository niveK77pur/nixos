{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.locate;
in {
  options.locate = {
    enable = lib.mkEnableOption "locate";
  };

  config = lib.mkIf cfg.enable {
    services.locate = {
      enable = true;
      package = pkgs.mlocate;
      prunePaths = [
        "/nix/store"
        "/nix/var/log/nix"
      ];
    };
  };
}
