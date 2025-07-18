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
          bootloader.systemd.enable = true;
          display = {
            enable = true;
            hyprland.enable = true;
          };
          gpu.nvidia = {
            enable = true;
            driverVersion = "stable";
            hybrid = {
              enable = true;
              nvidiaBusId = "PCI:1:0:0";
              intelBusId = "PCI:6:0:0";
            };
          };
          hm.enable = true;
          geoclue2.enable = true;
          bluetooth.enable = true;
        }
      ])

      (makeSystem "vm" [
        {
          display.enable = true;
          bootloader.systemd.enable = true;
          services.qemuGuest.enable = true;
          services.spice-vdagentd.enable = true;
        }
      ])
      (makeSystem "nixos" [
        {
          bootloader.grub.enable = true;
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

