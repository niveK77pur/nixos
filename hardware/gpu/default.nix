{lib, ...}: {
  options.gpu = {
    type = lib.mkOption {
      description = "Which GPU is being used";
      type = lib.types.enum ["amd" "none"];
      default = "none";
    };
  };

  imports = [
    ./nvidia.nix
    ./amd.nix
  ];
}
