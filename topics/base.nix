{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.base;
in {
  imports = [inputs.nix-index-database.nixosModules.default];

  options.base = {
    enable = lib.mkEnableOption "base";
    withComma = lib.mkEnableOption "comma";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      git.enable = true;
      lazygit.enable = true;
      yazi.enable = true;
      neovim.enable = true;
      bat.enable = true;
      nix-index-database.comma.enable = cfg.withComma;
    };
    environment.systemPackages = with pkgs; [
      jujutsu
      aria2
      jjui
      fd
      zellij
      ripgrep
      file
      viddy
    ];
  };
}
