{ pkgs, ... }:

{
  # Yayy interwebs
  networking = {  
    hostName = "nixos"; # *shrugs*
    networkmanager = {
      enable = true;  
      plugins = with pkgs; [
        networkmanager-openvpn
        networkmanager-openconnect
      ];
    }; # if nobody got me i know dhcp got me can i get an amen
  };

  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };  
}
