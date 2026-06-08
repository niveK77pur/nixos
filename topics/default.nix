{lib, ...}: {
  imports = [
    ./base.nix
    ./locate.nix
    ./cachix.nix
  ];

  config = {
    base.enable = lib.mkDefault true;
    cachix.enable = lib.mkDefault true;
  };
}
