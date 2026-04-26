{lib, ...}: {
  imports = [
    ./base.nix
    ./locate.nix
  ];

  config = {
    base.enable = lib.mkDefault true;
  };
}
