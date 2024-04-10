{pkgs, ...}: {
  config = {
    environment.systemPackages = with pkgs; [
      vieb
    ];
    programs.firefox.enable = true;
  };
}
