{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.audio.jack;
in {
  options.audio.jack = {
    enable = lib.mkEnableOption "jack";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      warnings =
        lib.optionals (!config.audio.pipewire.enable) "No JACK standalone config; only in combination with audio.pipewire.enable";
    }

    (lib.mkIf config.audio.pipewire.enable {
      services.pipewire.jack.enable = true;
    })

    (lib.mkIf (!config.audio.pipewire.enable) {
      })

    (lib.mkIf config.audio.enableTools {
      environment.systemPackages = [
        pkgs.qjackctl
      ];
    })
  ]);
}
