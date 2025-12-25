{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.topics;
in {
  options.topics = {
    pass = {
      enable = lib.mkEnableOption {
        description = "Enable pass, the standard UNIX password manager";
        default = false;
      };
    };
  };

  config = {
    environment.systemPackages = lib.lists.optional cfg.pass.enable pkgs.pass;

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
