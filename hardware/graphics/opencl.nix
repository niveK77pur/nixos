{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.gpu;
in {
  config = lib.mkIf (cfg.type != "none") (lib.mkMerge [
    (lib.mkIf (cfg.type == "amd") {
      hardware.opengl.extraPackages = with pkgs; [
        rocmPackages.clr.icd
      ];
    })

    {
      # check if OpenCL was correctly installed
      # programs.clinfo.enable = true;
    }
  ]);
}
