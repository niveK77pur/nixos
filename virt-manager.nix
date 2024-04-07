{...}: {
  fileSystems."/etc/nixos" = {
    device = "nixos_conf";
    label = "nixos_conf";
    fsType = "9p";
    options = ["virtio" "version=9p2000.L"];
  };

  services.qemuGuest.enable = true;
}
