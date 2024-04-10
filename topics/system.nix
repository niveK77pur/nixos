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
        default = true;
      };
    };
  };

  config = with pkgs; {
    environment.systemPackages = [
      pass
    ];

    services.locate = {
      enable = true;
      package = pkgs.mlocate;
      localuser = null; # disable warning
    };
  };
}
