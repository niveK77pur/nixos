{pkgs, ...}: {
  config = {
    environment.systemPackages = with pkgs; [
      steam
      lutris
      heroic
      mangohud
      ludusavi
      vulkan-tools # for vkcube
      glxinfo # for glxgears
    ];
  };
}
