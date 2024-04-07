{
  lib,
  config,
  ...
}: let
  cfg = config.gpu;
  gpuType = "amd";
in {
  imports = [
    ../graphics/opencl.nix
    ../graphics/vulkan.nix
  ];

  config = lib.mkIf (cfg.type == gpuType) {
    # drivers
    boot.initrd.kernelModules = ["amdgpu"];
    services.xserver.enable = true;
    services.xserver.videoDrivers = ["amdgpu"];
  };
}
