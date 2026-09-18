{ config, lib, pkgs, ... }:

let
  cfg = config.services.qbittorrentMullvad;
  namespace = "qbt";
  bridge = "qbt-br";
  hostVeth = "veth-qbt-br";
  namespaceVeth = "veth-qbt";
  namespaceAddress = "172.23.0.2";
  bridgeAddress = "172.23.0.1";

  vpnUp = pkgs.writeShellApplication {
    name = "${namespace}-vpn-up";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      gnugrep
      gawk
      iproute2
      iptables
      procps
      wireguard-tools
    ];
    text = ''
      set -euo pipefail

      config_file=${lib.escapeShellArg cfg.wireguardConfigFile}
      test -r "$config_file" || {
        echo "Mullvad WireGuard config is missing or unreadable: $config_file" >&2
        exit 1
      }

      # The file is read only at service start. Its private key is never
      # evaluated by Nix or embedded in the Nix store.
      # shellcheck disable=SC1090
      source <(
        grep -E '^[[:space:]]*(Address|DNS|Endpoint)[[:space:]]*=' "$config_file" \
          | tr -d ' '
      )
      : "''${Address:?WireGuard config is missing Address}"
      : "''${DNS:?WireGuard config is missing DNS}"
      : "''${Endpoint:?WireGuard config is missing Endpoint}"

      tunnel_address="''${Address%%,*}"
      case "$tunnel_address" in
        ([0-9]*.[0-9]*.[0-9]*.[0-9]*/[0-9]*) ;;
        (*)
          echo "WireGuard config must contain an IPv4 Address: $Address" >&2
          exit 1
          ;;
      esac

      endpoint_ip="''${Endpoint%:*}"
      endpoint_port="''${Endpoint##*:}"
      case "$endpoint_ip:$endpoint_port" in
        ([0-9]*.[0-9]*.[0-9]*.[0-9]*:[0-9]*) ;;
        (*)
          echo "Only IPv4 WireGuard endpoints are supported: $Endpoint" >&2
          exit 1
          ;;
      esac

      # A stale namespace can remain after an unclean shutdown.
      ip netns del ${namespace} 2>/dev/null || true
      ip link del ${bridge} 2>/dev/null || true

      ip netns add ${namespace}
      ip link add ${bridge} type bridge
      ip addr add ${bridgeAddress}/24 dev ${bridge}
      ip link set ${bridge} up

      ip link add ${hostVeth} type veth peer name ${namespaceVeth} netns ${namespace}
      ip link set ${hostVeth} master ${bridge}
      ip link set ${hostVeth} up
      ip -n ${namespace} addr add ${namespaceAddress}/24 dev ${namespaceVeth}
      ip -n ${namespace} link set ${namespaceVeth} up
      ip -n ${namespace} link set lo up
      ip netns exec ${namespace} sysctl -qw net.ipv6.conf.all.disable_ipv6=1

      ip link add ${namespace}0 type wireguard
      ip link set ${namespace}0 netns ${namespace}
      sed -E '/^[[:space:]]*(Address|DNS|MTU|Table|PreUp|PreDown|PostUp|PostDown|SaveConfig)[[:space:]]*=/d' \
        "$config_file" \
        | ip netns exec ${namespace} wg setconf ${namespace}0 /dev/stdin
      ip -n ${namespace} address add "$tunnel_address" dev ${namespace}0
      ip -n ${namespace} link set ${namespace}0 up

      # The encrypted WireGuard packets may reach only Mullvad's endpoint via
      # the host. Everything else in the namespace uses the tunnel.
      ip -n ${namespace} route add "$endpoint_ip/32" via ${bridgeAddress} dev ${namespaceVeth}
      ip -n ${namespace} route add default dev ${namespace}0

      install -d -m 0755 /etc/netns/${namespace}
      : > /etc/netns/${namespace}/resolv.conf
      for nameserver in $(tr ',' ' ' <<< "$DNS"); do
        printf 'nameserver %s\n' "$nameserver" >> /etc/netns/${namespace}/resolv.conf
      done

      ip netns exec ${namespace} iptables -P INPUT DROP
      ip netns exec ${namespace} iptables -P FORWARD DROP
      ip netns exec ${namespace} iptables -A INPUT -i lo -j ACCEPT
      ip netns exec ${namespace} iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      ip netns exec ${namespace} iptables -A INPUT -i ${namespaceVeth} -p tcp --dport ${toString cfg.webuiPort} -j ACCEPT
      ip netns exec ${namespace} iptables -A INPUT -i ${namespace}0 -p tcp --dport ${toString cfg.torrentingPort} -j ACCEPT
      ip netns exec ${namespace} iptables -A INPUT -i ${namespace}0 -p udp --dport ${toString cfg.torrentingPort} -j ACCEPT
      ip netns exec ${namespace} iptables -A OUTPUT -o ${namespaceVeth} -p udp -d "$endpoint_ip" --dport "$endpoint_port" -j ACCEPT
      ip netns exec ${namespace} iptables -A OUTPUT -o ${namespaceVeth} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      ip netns exec ${namespace} iptables -A OUTPUT -o ${namespaceVeth} -j DROP

      # Permit forwarding and NAT only for this namespace. The namespace's
      # firewall above is the kill switch for all non-WireGuard traffic.
      iptables -N ${namespace}-vpn-forward 2>/dev/null || true
      iptables -F ${namespace}-vpn-forward
      iptables -A ${namespace}-vpn-forward -j ACCEPT
      iptables -I FORWARD -i ${bridge} -j ${namespace}-vpn-forward
      iptables -I FORWARD -o ${bridge} -m conntrack --ctstate ESTABLISHED,RELATED -j ${namespace}-vpn-forward
      iptables -t nat -N ${namespace}-vpn-postrouting 2>/dev/null || true
      iptables -t nat -F ${namespace}-vpn-postrouting
      iptables -t nat -A ${namespace}-vpn-postrouting -j MASQUERADE
      iptables -t nat -A POSTROUTING -s ${namespaceAddress} -j ${namespace}-vpn-postrouting
    '';
  };

  vpnDown = pkgs.writeShellApplication {
    name = "${namespace}-vpn-down";
    runtimeInputs = with pkgs; [ iproute2 iptables ];
    text = ''
      set +e
      iptables -D FORWARD -i ${bridge} -j ${namespace}-vpn-forward
      iptables -D FORWARD -o ${bridge} -m conntrack --ctstate ESTABLISHED,RELATED -j ${namespace}-vpn-forward
      iptables -F ${namespace}-vpn-forward
      iptables -X ${namespace}-vpn-forward
      iptables -t nat -D POSTROUTING -s ${namespaceAddress} -j ${namespace}-vpn-postrouting
      iptables -t nat -F ${namespace}-vpn-postrouting
      iptables -t nat -X ${namespace}-vpn-postrouting
      ip netns del ${namespace}
      ip link del ${bridge}
      rm -f /etc/netns/${namespace}/resolv.conf
      rmdir /etc/netns/${namespace}
    '';
  };
in
{
  options.services.qbittorrentMullvad = {
    enable = lib.mkEnableOption "qBittorrent confined to a Mullvad WireGuard tunnel";

    wireguardConfigFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nixos/secrets/mullvad-qbittorrent.conf";
      description = ''
        Runtime path to a Mullvad WireGuard configuration file. This is a
        string deliberately: using a Nix path would copy the private key into
        the world-readable Nix store.
      '';
    };

    webuiPort = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "qBittorrent Web UI port, reachable locally at ${namespaceAddress}.";
    };

    torrentingPort = lib.mkOption {
      type = lib.types.port;
      default = 51820;
      description = "TCP and UDP BitTorrent listen port inside the VPN namespace.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    systemd.services.${namespace} = {
      description = "Mullvad WireGuard namespace for qBittorrent";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = [ pkgs.procps ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${vpnUp}/bin/${namespace}-vpn-up";
        ExecStop = "${vpnDown}/bin/${namespace}-vpn-down";
      };
    };

    services.qbittorrent = {
      enable = true;
      openFirewall = false;
      inherit (cfg) webuiPort torrentingPort;
      # Do not use serverConfig here: NixOS writes it before every start,
      # which would overwrite the password selected in the Web UI. Network
      # confinement is enforced by the namespace firewall instead.
      extraArgs = [ "--confirm-legal-notice" ];
    };

    systemd.services.qbittorrent = {
      bindsTo = [ "${namespace}.service" ];
      after = [ "${namespace}.service" ];
      requires = [ "${namespace}.service" ];
      serviceConfig = {
        NetworkNamespacePath = "/run/netns/${namespace}";
        BindReadOnlyPaths = [ "/etc/netns/${namespace}/resolv.conf:/etc/resolv.conf:norbind" ];
      };
    };
  };
}
