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
      bluez # for ps4 controller:
    ];

    hardware.bluetooth = {
      package = pkgs.bluez;
    };
  };
}
