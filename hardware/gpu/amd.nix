{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.gpu.amd;
in {
  options.gpu.amd = {
    enable = lib.mkEnableOption "amd";
  };

  config = lib.mkIf cfg.enable {
    # drivers
    boot.initrd.kernelModules = ["amdgpu"];
    services.xserver.enable = true;
    services.xserver.videoDrivers = ["amdgpu"];

    hardware.opengl.extraPackages = [
      pkgs.rocmPackages.clr.icd
    ];
  };
}
