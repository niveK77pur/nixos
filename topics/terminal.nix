{pkgs, ...}: {
  config = {
    environment.systemPackages = with pkgs; [
      lf
      git
      aria
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
