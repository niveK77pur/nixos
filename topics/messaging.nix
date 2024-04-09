{pkgs, ...}: {
  config = {
    environment.systemPackages = with pkgs; [
      discord
      ferdium
      thunderbird
      signal-desktop
    ];
  };
}
