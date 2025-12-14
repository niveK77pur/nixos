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
    boot.initrd.kernelModules = ["amdgpu"];

    services = {
      xserver = {
        enable = true;
        videoDrivers = ["amdgpu"];
      };
      lact = {
        enable = true;
      };
    };

    environment.systemPackages = [
      pkgs.clinfo # OpenCL
    ];

    systemd.tmpfiles.rules = [
      # HIP
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];

    hardware.graphics = {
      enable = true; # OpenGL
      enable32Bit = true; # Vulkan
      extraPackages = [
        pkgs.rocmPackages.clr.icd # OpenCL
        pkgs.libvdpau-va-gl
      ];
    };
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "radeonsi"; # VA-API
      VDPAU_DRIVER = "radeonsi"; # VDPAU
    };
  };
}
