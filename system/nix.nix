{
  lib,
  config,
  ...
}: let
  modname = "nix-config";
  cfg = config.${modname};
in {
  options.${modname} = {
    enable = lib.mkEnableOption "${modname}" // {default = true;};
  };

  config = lib.mkIf cfg.enable {
    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
      optimise = {
        automatic = true;
      };
      gc = {
        automatic = true;
        dates = "weekly";
      };
    };
  };
}
