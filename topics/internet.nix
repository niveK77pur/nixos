{pkgs, ...}: {
  config = {
    environment.systemPackages = with pkgs; [
      firefox
      vieb
    ];
  };
}
