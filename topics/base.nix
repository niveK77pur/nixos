{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.base;
in {
  options.base = {
    enable = lib.mkEnableOption "base";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      git.enable = true;
      lazygit.enable = true;
      yazi.enable = true;
      neovim.enable = true;
      bat.enable = true;
    };
    environment.systemPackages = with pkgs; [
      jujutsu
      aria2
      jjui
      fd
      zellij
      ripgrep
      file
    ];
  };
}
