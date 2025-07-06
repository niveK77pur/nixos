{
  lib,
  config,
  ...
}: let
  cfg = config.audio.pulseaudio;
in {
  options.audio.pulseaudio = {
    enable = lib.mkEnableOption "pulseaudio";
  };

  config = lib.mkIf cfg.enable {
    hardware.pulseaudio = {
      enable = true;
      support32Bit = true;
    };
    nixpkgs.config.pulseaudio = true;
  };
}
