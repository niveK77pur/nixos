{pkgs, ...}: {
  config = {
    environment.systemPackages = with pkgs; [
      steam
      lutris
      heroic
      mangohud
      gamemode
      gpu-screen-recorder
      gpu-screen-recorder-gtk
      ludusavi
      vulkan-tools # for vkcube
      glxinfo # for glxgears
    ];
  };
}
