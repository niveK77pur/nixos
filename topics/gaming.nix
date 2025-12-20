{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.gaming;
in {
  options.gaming = {
    enable = lib.mkEnableOption "steam";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      lutris
      heroic
      mangohud
      gpu-screen-recorder
      gpu-screen-recorder-gtk
      ludusavi
      vulkan-tools # for vkcube
      mesa-demos # for glxgears
      bluez # for ps4 controller:
    ];

    programs = {
      steam = {
        enable = true;
        gamescopeSession = {
          enable = true;
        };
      };

      gamemode.enable = true;

      gamescope = {
        enable = true;
      };
    };

    hardware.bluetooth = {
      package = pkgs.bluez;
    };
  };
}
