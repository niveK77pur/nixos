{
  description = "NixOS configuration of kevin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    alejandra = {
      url = "github:kamadorueda/alejandra/3.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    # self,
    nixpkgs,
    alejandra,
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
            ./system/configuration.nix
            ./system/bluetooth.nix
            ./hardware-configuration.nix
            # ./users/kevin.nix
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
        }
      ])
      (makeSystem "nixos" [
        {
          display.enable = true;
        }
      ])
    ];

    devShells.${system}.default = pkgs.mkShell {
      name = "nixos";
      packages = [
        pkgs.nixd
        pkgs.nil
        pkgs.statix
        alejandra.defaultPackage.${system}
        pkgs.lazygit
      ];
    };
  };
}
# vim: fdm=marker

