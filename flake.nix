{
  description = "Silver's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    millennium.url =
      "github:SteamClientHomebrew/Millennium?dir=packages/nix";

    nixcord.url = 
      "github:4evy/nixcord";

    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs = { 
    self, 
    nixpkgs, 
    home-manager,
    plasma-manager,
    millennium,
    nix-flatpak,
    ... 
  }@inputs: 
  {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = {
        inherit inputs;
      };

      modules = [
        ./configuration.nix

        home-manager.nixosModules.home-manager

        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

	  home-manager.backupFileExtension = "hm-backup";

          home-manager.extraSpecialArgs = {
            inherit inputs;
          };

          home-manager.users.silver = {
	    imports = [
	      ./home.nix
	      plasma-manager.homeModules.plasma-manager
	      nix-flatpak.homeManagerModules.nix-flatpak
	    ];
          };
        }
      ];
    };
  };
}
