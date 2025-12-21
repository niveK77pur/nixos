{
  lib,
  config,
  ...
}: let
  modname = "system";
in {
  imports =
    map
    (file: ./. + "/${file}")
    (lib.filter
      (file: file != "default.nix")
      (lib.attrNames (builtins.readDir ./.)));

  options.${modname} = {
    enableAll = lib.mkEnableOption "${modname}";
  };

  config = lib.mkIf config.${modname}.enableAll {
    bluetooth.enable = lib.mkDefault true;
    display.enable = lib.mkDefault true;
    nix-config.enable = lib.mkDefault true;
    ssh.enable = lib.mkDefault true;
    printing.enable = lib.mkDefault true;
  };
}
