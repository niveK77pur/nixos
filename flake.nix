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
    ...
  } @ args: let
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
      ];
    };

    nixosConfigurations.titan = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        deviceName = "titan"; # must match configuration name
      };
      modules = [
        ./system/configuration.nix
        ./hardware-configuration.nix
        ./users/kevin.nix
        ./topics
        ./hardware/gpu
        {
          display.enable = true;
          gpu.type = "nvidia";
          gpu.nvidia.nvidiaBusId = "PCI:1:0:0";
          gpu.nvidia.intelBusId = "PCI:6:0:0";
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
      ];
    };

    devShells.${system}.default = pkgs.mkShell {
      packages = [
        args.alejandra.defaultPackage.${system}
        pkgs.lazygit
      ];
    };
  };
}
