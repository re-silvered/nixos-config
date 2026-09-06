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
      # get ready for some bullshit
      dispatcherScripts = [
        {
        source = pkgs.writeShellScript "select-dns" ''
          interface="$1"
          event="$2"
  
          [ "$event" = "up" ] || exit 0
  
          DNS="$(
            ${pkgs.networkmanager}/bin/nmcli \
              -g IP4.DNS device show "$interface" |
            head -n1
          )"
  
          [ -n "$DNS" ] || exit 0
  
          result="$(
            ${pkgs.bind}/bin/dig \
              +time=2 \
              +tries=1 \
              +short \
              @"$DNS" \
              doubleclick.net 
          )"

          if [ -z "$result" ]; then
            echo "DNS $DNS is secure"
          else
            echo "Improper DNS server given from DHCP; switching to Quad9"
  
            ${pkgs.systemd}/bin/resolvectl dns \
              "$interface" \
              9.9.9.9 \
              149.112.112.112
          fi
        '';
        type = "basic";
        }
      ];
    };
  };

  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };
}
