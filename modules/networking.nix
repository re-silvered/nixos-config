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
  
          if ! result="$(
            ${pkgs.bind}/bin/dig \
              +time=2 \
              +tries=1 \
              +short \
              @"$DNS" \
              doubleclick.net 
          )"; then
            echo "DNS query to $DNS failed; leaving DNS unchanged"
            exit 0
          fi

          if [ -z "$result" ]; then
            echo "DNS $DNS returned no address for doubleclick.net; leaving DNS unchanged"
          else
            echo "DNS $DNS resolves doubleclick.net; switching to Quad9"
  
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

  services.resolved.enable = true;

  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };
}
