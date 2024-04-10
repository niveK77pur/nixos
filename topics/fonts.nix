{pkgs, ...}: {
  config = {
    environment.systemPackages = with pkgs; [
      fira-code-nerdfont
      victor-mono
    ];
  };
}
