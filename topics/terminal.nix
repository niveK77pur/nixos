{pkgs, ...}: {
  config = {
    environment.systemPackages = with pkgs; [
      lf
      git
      aria
      lazygit
      starship
      wezterm
      atuin
      neovim
      zellij
    ];
  };
}
