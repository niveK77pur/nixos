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
    bootloader.enable = lib.mkDefault true;
    configuration.enable = lib.mkDefault true;
    display-server.enable = lib.mkDefault true;
    kernel.enable = lib.mkDefault true;
    networking.enable = lib.mkDefault true;
    nix.enable = lib.mkDefault true;
    ssh.enable = lib.mkDefault true;
  };
}
