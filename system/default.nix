{
  lib,
  config,
  ...
}: let
  modname = "system";
in {
  options.${modname} = {
    enableAll = lib.mkEnableOption "${modname}";
  };

  config = lib.mkIf config.${modname}.enableAll {
    bluetooth.enable = lib.mkDefault true;
    display.enable = lib.mkDefault true;
    nix-config.enable = lib.mkDefault true;
    ssh.enable = lib.mkDefault true;
  };
}
