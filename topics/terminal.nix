{pkgs, ...}: {
  config = {
    environment.systemPackages = with pkgs; [
      lf
      git
      jujutsu
      aria2
      lazygit
      fd
      starship
      wezterm
      atuin
      neovim
      zellij
      z-lua
      bat
      ripgrep
      file
    ];
  };
}
