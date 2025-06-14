{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.audio;
in {
  imports = [
    ./jack.nix
    ./pipewire.nix
    ./pulseaudio.nix
  ];

  options.audio = {
    enable = lib.mkEnableOption "audio";
    enableTools = lib.mkEnableOption "audio";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      audio.pipewire.enable = true;
    })

    (lib.mkIf cfg.enableTools {
      environment.systemPackages = [
        pkgs.pavucontrol
      ];
    })
  ];
}
