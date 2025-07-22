{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.audio.pipewire;
in {
  options.audio.pipewire = {
    enable = lib.mkEnableOption "pipewire";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true;
        # If you want to use JACK applications, uncomment this
        #jack.enable = true;
      };
    }

    (lib.mkIf config.audio.enableTools {
      environment.systemPackages = [
        pkgs.qpwgraph
      ];
    })
  ]);
}
