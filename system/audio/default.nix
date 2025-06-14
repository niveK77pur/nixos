{
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
  };

  config = lib.mkIf cfg.enable {
    audio.pipewire.enable = true;
  };
}
