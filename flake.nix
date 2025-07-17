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
    #  {{{
    makeSystem = systemName: modules: {
      "${systemName}" = nixpkgs.lib.nixosSystem {
        inherit system;

        modules =
          [
            ./system
            ./hardware-configuration.nix
            ./users/user.nix
            ./topics
            ./hardware/gpu
          ]
          ++ modules;

        specialArgs = {
          deviceName = "${systemName}";
        };
      };
    }; #  }}}
  in {
    nixosConfigurations = pkgs.lib.mergeAttrsList [
      (makeSystem "tuxedo" [
        {
          display.enable = true;
        }
      ])

      (makeSystem "titan" [
        {
          user = {
            name = "kevin";
          };
          display.enable = true;
          gpu = {
            type = "nvidia";
            hybrid = {
              enable = true;
              nvidiaBusId = "PCI:1:0:0";
              intelBusId = "PCI:6:0:0";
              driverVersion = "stable";
            };
          };
        }
      ])

      (makeSystem "vm" [
        {
          display.enable = true;
          services.qemuGuest.enable = true;
          services.spice-vdagentd.enable = true;
        }
      ])
      (makeSystem "nixos" [
        {
          display.cinnamon.enable = true;
          user = {
            name = "tuxkuni";
          };
          services.qemuGuest.enable = true;
          services.spice-vdagentd.enable = true;
        }
      ])
    ];

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

