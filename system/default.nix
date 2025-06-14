{
  lib,
  config,
  ...
}: let
  modname = "system";
in {
  imports = [
    ./audio
    ./bluetooth.nix
    ./bootloader.nix
    ./configuration.nix
    ./display-server
    ./kernel.nix
    ./networking.nix
    ./nix.nix
    ./printing.nix
    ./ssh.nix
  ];

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
