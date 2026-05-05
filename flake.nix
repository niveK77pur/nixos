{
  description = "NixOS configuration of kevin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    # self,
    nixpkgs,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    inherit (pkgs) lib;
    #  {{{
    makeSystem = systemName: modulePath: {
      "${systemName}" = nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          {
            networking.hostName = systemName;
          }
          ./system
          ./hardware-configuration/${systemName}.nix
          ./users/user.nix
          ./topics
          ./hardware/gpu
          modulePath
        ];

        specialArgs = {
          inherit systemName;
        };
      };
    }; #  }}}
  in {
    nixosConfigurations =
      lib.mergeAttrsList
      (map
        (f: makeSystem (lib.removeSuffix ".nix" (baseNameOf f)) f)
        (lib.fileset.toList ./nixosConfigurations));

    devShells.${system}.default = pkgs.mkShell {
      name = "nixos";
      packages = [
        pkgs.nixd
        pkgs.nil
        pkgs.statix
        pkgs.alejandra
        pkgs.lazygit
      ];
    };
  };
}
# vim: fdm=marker

