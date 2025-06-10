{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ./awesome.nix
    ./cinnamon.nix
    ./hyprland.nix
    ./plasma.nix
  ];

  config = lib.mkMerge [
    # Configure X11
    (lib.mkIf config.services.xserver.enable {
      environment.systemPackages = with pkgs; [
        acpilight
        xclip
        dmenu
        wl-clipboard-rs
        wl-clipboard-x11
      ];
      services.xserver.xkb = {
        layout = "ch";
        variant = "fr";
      };
    })
  ];
}
