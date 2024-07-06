{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.gpu;
  gpuType = "nvidia";
in {
  options.gpu.nvidia = {
    driverVersion = lib.mkOption {
      description = "Which NVIDIA driver to use";
      type = lib.types.enum [
        # See https://nixos.wiki/wiki/Nvidia
        "latest"
        "stable"
        "beta"
        "production"
        "vulkan_beta"
        "legacy_470"
        "legacy_390"
        "legacy_340"
      ];
      default = "latest";
    };
  };

  imports = [../graphics/opengl.nix];

  config = lib.mkIf (cfg.type == gpuType) (lib.mkMerge [
    {
      # Enable OpenGL (TODO: replace with imports above)
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      services.xserver.videoDrivers = ["nvidia"];
      hardware.nvidia = {
        # Modesetting is required.
        modesetting.enable = true;

        # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
        # Enable this if you have graphical corruption issues or application crashes after waking
        # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
        # of just the bare essentials.
        powerManagement.enable = false;

        # Fine-grained power management. Turns off GPU when not in use.
        # Experimental and only works on modern Nvidia GPUs (Turing or newer).
        powerManagement.finegrained = false;

        # Use the NVidia open source kernel module (not to be confused with the
        # independent third-party "nouveau" open source driver).
        # Support is limited to the Turing and later architectures. Full list of
        # supported GPUs is at:
        # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
        # Only available from driver 515.43.04+
        # Currently alpha-quality/buggy, so false is currently the recommended setting.
        open = false;

        # Enable the Nvidia settings menu,
        # accessible via `nvidia-settings`.
        nvidiaSettings = true;

        package = config.boot.kernelPackages.nvidiaPackages.${cfg.nvidia.driverVersion};
      };
    }

    (lib.mkIf cfg.hybrid.enable {
      hardware.nvidia.prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        # intelBusId = "${cfg.hybrid.intelBusId}";
        amdgpuBusId = "${cfg.hybrid.intelBusId}";
        nvidiaBusId = "${cfg.hybrid.nvidiaBusId}";
      };
      environment.systemPackages = [
        (pkgs.writeShellScriptBin "prime-run" ''
          export __NV_PRIME_RENDER_OFFLOAD=1
          export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
          export __GLX_VENDOR_LIBRARY_NAME=nvidia
          export __VK_LAYER_NV_optimus=NVIDIA_only
          exec "$@"
        '')
      ];
    })
  ]);
}
