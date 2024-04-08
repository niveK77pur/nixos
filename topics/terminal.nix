{pkgs, ...}: {
  config = {
    environment.systemPackages = with pkgs; [
      lf
      lazygit
      starship
      wezterm
      atuin
      neovim
      zellij
    ];
  };
}
