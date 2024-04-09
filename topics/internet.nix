{pkgs, ...}: {
  config = {
    environment.systemPackages = with pkgs; [
      firefox-bin
      vieb
    ];
  };
}
