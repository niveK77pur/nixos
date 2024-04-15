{
  description = "A very ADVANCED flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    alejandra = {
      url = "github:kamadorueda/alejandra/3.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    alejandra,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    nixosConfigurations.tuxedo = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        deviceName = "tuxedo"; # must match configuration name
      };
      modules = [
        ./system/configuration.nix
        ./hardware-configuration.nix
        ./virt-manager.nix
        ./users/kevin.nix
        # ./hardware/gpu
        {
          display.enable = true;
          # gpu.type = "amd";
        }
        {
          environment.systemPackages = [alejandra.defaultPackage.${system}];
        }
      ];
    };

    nixosConfigurations.titan = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        deviceName = "titan"; # must match configuration name
      };
      modules = [
        ./system/configuration.nix
        ./system/bluetooth.nix
        ./hardware-configuration.nix
        ./users/kevin.nix
        ./topics
        ./hardware/gpu
        {
          display.enable = true;
          gpu.type = "nvidia";
          gpu.hybrid.enable = true;
          gpu.hybrid.nvidiaBusId = "PCI:1:0:0";
          gpu.hybrid.intelBusId = "PCI:6:0:0";
        }
        {
          environment.systemPackages = [alejandra.defaultPackage.${system}];
        }
      ];
    };

    nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        deviceName = "vm"; # must match configuration name
      };
      modules = [
        ./system/configuration.nix
        ./hardware-configuration.nix
        ./virt-manager.nix
        ./users/kevin.nix
        {
          display.enable = true;
        }
        {
          environment.systemPackages = [alejandra.defaultPackage.${system}];
        }
      ];
    };

    devShells.${system}.default = pkgs.mkShell {
      packages = [
        alejandra.defaultPackage.${system}
        pkgs.lazygit
      ];
    };
  };
}
