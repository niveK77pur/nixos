{
  lib,
  config,
  ...
}: let
  cfg = config.cachix;
in {
  options.cachix = {
    enable = lib.mkEnableOption "cachix";
  };

  config = lib.mkIf cfg.enable {
    nix = {
      settings = {
        substituters = [
          "https://nivek77pur-nixos.cachix.org"
          "https://noctalia.cachix.org"
        ];
        trusted-public-keys = [
          "nivek77pur-nixos.cachix.org-1:tBIn4SNnDdzl9g4NkKWMOyG4HiX7g3z7sXNhjvaib08="
          "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        ];
      };
    };
  };
}
