{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.user;
in {
  options.user = {
    name = lib.mkOption {
      type = lib.types.str;
      description = "Name of the user";
    };
    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional groups the user should be a part of";
    };
  };

  config = {
    programs.fish.enable = true;
    users.users."${cfg.name}" = {
      isNormalUser = true;
      extraGroups = lib.concatLists [
        ["networkmanager" "wheel"]
        cfg.extraGroups
        (lib.lists.optional config.audio.pulseaudio.enable "audio")
      ];
      shell = pkgs.fish;
    };
  };
}
