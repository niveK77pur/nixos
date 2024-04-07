{
  lib,
  config,
  ...
}: let
  cfg = config.gpu;
  gpuType = "nvidia";
in {
  config = lib.mkIf (cfg.type == gpuType) {
    services.xserver.videoDrivers = ["nvidia"];
  };
}
