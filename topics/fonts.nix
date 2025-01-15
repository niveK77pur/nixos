{pkgs, ...}: {
  config = {
    environment.systemPackages = with pkgs; [
      nerd-fonts.fira-code
      victor-mono
    ];
  };
}
