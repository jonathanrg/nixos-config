#Variables
{ lib, inputs, nixpkgs, nixpkgs-stable, disko, home-manager, wallpaperdownloader, username, autofirma-nix, sicos-config, nix-flatpak, self,... }:
let
  # System architecture
  system = "x86_64-linux";

  # Unstable packages
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  # Stable packages
  pkgs-stable = import nixpkgs-stable {
    inherit system;
    config.allowUnfree = true;
  };

  lib = nixpkgs.lib;

  # Function to generate a host configuration
  mkHost = { hostName, desktop, extraModules ? [], homeManagerExtraImports ? [] }:

    let
      hostArg = { inherit hostName desktop; };
    in
    lib.nixosSystem {

      inherit system;

      specialArgs = {
        inherit inputs username pkgs-stable;
        host = hostArg;
      };

      modules = extraModules ++ [
        
        # Nix-flatpak module
        nix-flatpak.nixosModules.nix-flatpak
        
        # Common configuration for all hosts
        ./configuration.nix

        # Import sicos module and activate options
        sicos-config.nixosModules.sicos-hyprland
        {
          programs.sicos.hyprland = {
            enable = true;
            theming.enable = true;
            powerManagement.enable = true;
            insync.enable = true;
            insync.package = pkgs-stable.insync;
            kanshi.enable = true;

            # Custom config files

            # Hyprland
            hyprland.configFile = builtins.path { path = ../home-manager/desktop/hyprland/config/hyprland.conf; };

            # Hyprlock
            hyprlock.profilePicture = builtins.path { path = ../home-manager/desktop/hyprland/config/user.jpg; };

            # Kanshi
            kanshi.configFile = builtins.path { path = ../home-manager/desktop/hyprland/programs/kanshi/config; };

            # Waybar
            waybar.configFile = builtins.path { path = ../home-manager/desktop/hyprland/programs/waybar/config.jsonc; };
            waybar.styleFile = builtins.path { path = ../home-manager/desktop/hyprland/programs/waybar/style.css; };

            # Scripts
            scripts.path = builtins.path { path = ../home-manager/desktop/hyprland/scripts; };  

          };
        }

        # Home Manager module
        home-manager.nixosModules.home-manager {
          # Module configuration
          home-manager.backupFileExtension = "backup";
          home-manager.useGlobalPkgs = false;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {
            inherit username pkgs;
            host = hostArg;
          };
          home-manager.users.${username} = {
            # Import sicos home manager module
            imports = [ 
              sicos-config.homeManagerModules.sicos-hyprland
              (import ./home.nix)
            ];
          };
        }
      ];
    };

  # Modules for VM
  vmModules = [
    disko.nixosModules.disko {
      _module.args.disks = [ "/dev/vda" ];
      imports = [(import ./vm/disko-config.nix)];
    }
    ./vm/hardware-configuration.nix
    ./efi-configuration.nix
    ./vm/configuration.nix
  ];
  vmHomeManagerExtraImports = [ (import ./vm/home.nix) ];

  # Modules for Kratos
  kratosModules = [
    disko.nixosModules.disko {
      _module.args.disks = [ "/dev/nvme0n1" ];
      imports = [(import ./kratos/disko-config.nix)];
    }
    ./kratos/hardware-configuration.nix
    ./efi-configuration.nix
    ./kratos/configuration.nix
    # autofirma-nix.nixosModules.default
    # # It is a module itself!
    # ({ config, pkgs, ... }: {
    #   # The autofirma command becomes available system-wide
    #   programs.autofirma = {
    #     enable = true;
    #     firefoxIntegration.enable = true;
    #   };
    #   # # DNIeRemote integration for using phone as NFC reader
    #   # programs.dnieremote = {
    #   #   enable = true;
    #   # };
    #   # The FNMT certificate configurator
    #   programs.configuradorfnmt = {
    #     enable = true;
    #     firefoxIntegration.enable = true;
    #   };
    #   # Firefox configured to work with AutoFirma
    #   programs.firefox = {
    #     enable = true;
    #     policies.SecurityDevices = {
    #       "OpenSC PKCS#11" = "${pkgs.opensc}/lib/opensc-pkcs11.so";
    #       "DNIeRemote" = "${config.programs.dnieremote.finalPackage}/lib/libdnieremotepkcs11.so";
    #     };
    #   };
    #   # Enable PC/SC smart card service
    #   services.pcscd.enable = true;
    # })
  ];
in
{
  # VM profile
  vm = mkHost {
    hostName = "experimental";
    desktop = "plasma";
    extraModules = vmModules;
    homeManagerExtraImports = vmHomeManagerExtraImports;
  };

  # Kratos profiles
  "kratos-plasma" = mkHost {
    hostName = "kratos";
    desktop = "plasma";
    extraModules = kratosModules;
  };
  "kratos-hyprland" = mkHost {
    hostName = "kratos";
    desktop = "hyprland";
    extraModules = kratosModules;
  };
}