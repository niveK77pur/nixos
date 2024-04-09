{lib, ...}: {
  options.gpu = {
    type = lib.mkOption {
      description = "Which GPU is being used";
      type = lib.types.enum ["amd" "nvidia" "none"];
      default = "none";
    };
    hybrid = {
      enable = lib.mkEnableOption "Enable NVIDIA Optimus PRIME (necessary for laptops)";
      intelBusId = lib.mkOption {
        description = "Bus ID Value for iGPU";
        type = lib.types.str;
      };
      nvidiaBusId = lib.mkOption {
        description = "Bus ID Value for dGPU";
        type = lib.types.str;
      };
    };
  };

  imports = [
    ./nvidia.nix
    ./amd.nix
  ];
}
