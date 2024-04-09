{lib, ...}: {
  options.gpu = {
    type = lib.mkOption {
      description = "Which GPU is being used";
      type = lib.types.enum ["amd" "nvidia" "none"];
      default = "none";
    };
    hybrid = {
      enable = lib.mkEnableOption "Enable NVIDIA Optimus PRIME (necessary for laptops)";
    };
  };

  imports = [
    ./nvidia.nix
    ./amd.nix
  ];
}
