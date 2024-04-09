{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.display;
in {
  options.display = {
    enable = lib.mkEnableOption "Enable the display";
    windowManager = lib.mkOption {
      description = "Which of the configured window managers to use";
      type = lib.types.enum [
        "plasma"
        "cinnamon"
        "hyprland"
      ];
      default = "plasma";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Enable the KDE Plasma Desktop Environment
    (lib.mkIf (cfg.windowManager == "plasma") {
      services.xserver.enable = true;
      services.xserver.displayManager.sddm.enable = true;
      services.desktopManager.plasma6.enable = true;
      environment.systemPackages = [
        pkgs.plasma-pass
      ];
    })

    # Enable the Cinnamon window manager
    (lib.mkIf (cfg.windowManager == "cinnamon") {
      services.xserver.enable = true;
      services.xserver.displayManager.lightdm.enable = true;
      services.xserver.desktopManager.cinnamon.enable = true;
    })

    # Enable the Hyprland window manager
    (lib.mkIf (cfg.windowManager == "hyprland") {
      programs.hyprland.enable = true;
      programs.hyprland.xwayland.enable = true;
      # enable screen-sharing on wlroots-based compositor
      xdg.portal.wlr.enable = true;
    })

    # Configure X11
    (lib.mkIf config.services.xserver.enable {
      environment.systemPackages = with pkgs; [
        acpilight
        xclip
      ];
      services.xserver.xkb = {
        layout = "ch";
        variant = "fr";
      };
    })
  ]);
}
