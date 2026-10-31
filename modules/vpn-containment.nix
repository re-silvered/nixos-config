{ config, lib, pkgs, ... }:
let
  cfg = config.services.vpnContainment;

  configuredPrograms = {
    firefox = {
      mode = "separate";
      package = config.home-manager.users.${cfg.user}.programs.firefox.finalPackage;
      args = [ "--no-remote" ] ++ lib.optionals
        (cfg.programs.firefox.mode == "separate")
        [ "--name" "firefox-vpn" "--class" "firefox-vpn" "-P" "vpn" ];
      desktopName = "Firefox (VPN)";
      categories = [ "Network" "WebBrowser" ];
      startupWMClass = if cfg.programs.firefox.mode == "separate" then "firefox-vpn" else null;
    };
    thunderbird = {
      mode = "always";
      package = pkgs.thunderbird;
      args = [ "--no-remote" ];
      desktopName = "Thunderbird";
      icon = "thunderbird";
      categories = [ "Network" "Email" ];
      mimeTypes = [ "x-scheme-handler/mailto" ];
    };
  };

  programs = lib.filterAttrs (_: app: app.enable) cfg.programs;
  helpers = lib.mapAttrs (name: app: let
    user = cfg.user;
    home = config.users.users.${user}.home;
    package = app.package;
    args = app.args;
  in pkgs.writeShellScript "${name}-vpn-enter" ''
    set -euo pipefail
    ${pkgs.systemd}/bin/systemctl start ${name}-vpn.service
    display="$1"; wayland="$2"; xauthority="$3"
    shift 3
    uid=$(${pkgs.coreutils}/bin/id -u ${user})
    gid=$(${pkgs.coreutils}/bin/id -g ${user})
    # Enter the namespace as root, then drop privileges before running the app.
    exec ${pkgs.iproute2}/bin/ip netns exec ${name}-vpn \
      ${pkgs.util-linux}/bin/setpriv --reuid="$uid" --regid="$gid" --init-groups \
      ${pkgs.coreutils}/bin/env -i \
      HOME=${lib.escapeShellArg home} USER=${user} LOGNAME=${user} \
      PATH=/run/current-system/sw/bin:/etc/profiles/per-user/${user}/bin \
      DISPLAY="$display" WAYLAND_DISPLAY="$wayland" XAUTHORITY="$xauthority" \
      XDG_RUNTIME_DIR="/run/user/$uid" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
      XDG_DATA_DIRS=/etc/profiles/per-user/${user}/share:/run/current-system/sw/share \
      MOZ_DBUS_REMOTE=0 \
      ${lib.getExe package} ${lib.escapeShellArgs args} "$@"
  '') programs;
  launchers = lib.mapAttrs (name: app: pkgs.writeShellScriptBin
    (if app.mode == "always" then name else "${name}-vpn") ''
      exec /run/wrappers/bin/sudo -n ${helpers.${name}} \
        "''${DISPLAY-}" "''${WAYLAND_DISPLAY-}" "''${XAUTHORITY-}" "$@"
    '') programs;
  commandName = name: app: if app.mode == "always" then name else "${name}-vpn";

  qbittorrentModule =
    { config, lib, pkgs, ... }:
    let
      cfg = config.services.qbittorrentVPN;
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
            echo "WireGuard config is missing or unreadable: $config_file" >&2
            exit 1
          }

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
      options.services.qbittorrentVPN = {
        enable = lib.mkEnableOption "qBittorrent confined to a WireGuard tunnel";

        wireguardConfigFile = lib.mkOption {
          type = lib.types.str;
          default = "/etc/nixos/secrets/wireguard-qbittorrent.conf";
          description = ''
            Runtime path to a WireGuard config file.
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
          description = "WireGuard namespace for qBittorrent";
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
    };


in {
  imports = [ qbittorrentModule ];

  options.services.vpnContainment = {
    enable = lib.mkEnableOption "application VPN containment";
    user = lib.mkOption { type = lib.types.str; default = "silver"; };
    programs = lib.mkOption {
      default = {};
      description = "Applications to VPN segment";
      type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
        options = {
          enable = lib.mkOption { type = lib.types.bool; default = true; };
          package = lib.mkOption { type = lib.types.package; };
          mode = lib.mkOption {
            type = lib.types.enum [ "always" "separate" ];
            default = "always";
            description = "always replaces the normal command and desktop entry; separate adds a second launcher.";
          };
          wireguardConfigFile = lib.mkOption {
            type = lib.types.str;
            default = "/etc/nixos/secrets/wireguard-${name}.conf";
            description = "Runtime WireGuard configuration path";
          };
          args = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
          desktopName = lib.mkOption { type = lib.types.str; default = name; };
          desktopId = lib.mkOption { type = lib.types.str; default = name; };
          icon = lib.mkOption { type = lib.types.str; default = "network-vpn"; };
          categories = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ "Network" ]; };
          mimeTypes = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
          startupWMClass = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
        };
      }));
    };
    qbittorrent = {
      enable = lib.mkEnableOption "qBittorrent VPN containment";
      wireguardConfigFile = lib.mkOption {
        type = lib.types.str;
        default = "/etc/nixos/secrets/wireguard-qbittorrent.conf";
      };
      webuiPort = lib.mkOption {
        type = lib.types.port;
        default = 8080;
      };
      torrentingPort = lib.mkOption {
        type = lib.types.port;
        default = 51820;
      };
    };
  };

  config = lib.mkMerge [
    {
      services.vpnContainment = {
        enable = lib.mkDefault true;
        programs = configuredPrograms;
        qbittorrent.enable = lib.mkDefault true;
      };
    }
    (lib.mkIf cfg.enable {
      services.qbittorrentVPN = cfg.qbittorrent;

      environment.systemPackages = map lib.hiPrio (lib.attrValues launchers);
      security.sudo.extraRules = [{
        users = [ cfg.user ];
        commands = lib.mapAttrsToList (_: helper: {
          command = toString helper;
          options = [ "NOPASSWD" ];
        }) helpers;
      }];
      systemd.services = lib.mapAttrs' (name: app: let
        ns = "${name}-vpn";
      in lib.nameValuePair ns {
        description = "VPN namespace for ${name}";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        path = with pkgs; [ coreutils gnugrep gnused iproute2 wireguard-tools procps ];
        serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
        script = ''
          set -euo pipefail
          file=${lib.escapeShellArg app.wireguardConfigFile}
          test -r "$file"
          address=$(sed -nE 's/^[[:space:]]*Address[[:space:]]*=[[:space:]]*([^, ]+).*/\1/p' "$file")
          dns=$(sed -nE 's/^[[:space:]]*DNS[[:space:]]*=[[:space:]]*(.*)/\1/p' "$file")
          [[ "$address" == *.*/* && -n "$dns" ]]
          ip netns add ${ns}
          ip link add ${ns} type wireguard
          ip link set ${ns} netns ${ns}
          sed -E '/^[[:space:]]*(Address|DNS|MTU|Table|PreUp|PreDown|PostUp|PostDown|SaveConfig)[[:space:]]*=/d' "$file" \
            | ip netns exec ${ns} wg setconf ${ns} /dev/stdin
          ip -n ${ns} addr add "$address" dev ${ns}
          ip -n ${ns} link set ${ns} mtu 1380 up
          ip -n ${ns} link set lo up
          ip netns exec ${ns} sysctl -qw net.ipv6.conf.all.disable_ipv6=1
          ip -n ${ns} route add default dev ${ns}
          install -d -m 0755 /etc/netns/${ns}
          : > /etc/netns/${ns}/resolv.conf
          for server in $(tr ',' ' ' <<< "$dns"); do
            printf 'nameserver %s\n' "$server" >> /etc/netns/${ns}/resolv.conf
          done
          sed -E 's/^hosts:.*/hosts: files dns/' /etc/nsswitch.conf > /etc/netns/${ns}/nsswitch.conf
        '';
        preStart = ''
          ip netns del ${ns} 2>/dev/null || true
          ip link del ${ns} 2>/dev/null || true
        '';
        postStop = ''
          ip netns del ${ns} 2>/dev/null || true
          ip link del ${ns} 2>/dev/null || true
          rm -rf /etc/netns/${ns}
        '';
      }) programs;

      home-manager.users.${cfg.user} = { config, ... }: {
        home.packages = lib.concatLists (lib.mapAttrsToList (name: app: [
          (lib.hiPrio launchers.${name})
          (lib.lowPrio app.package)
        ]) programs);
        xdg.desktopEntries = lib.mapAttrs' (name: app:
          lib.nameValuePair (if app.mode == "always" then app.desktopId else "${app.desktopId}-vpn") {
            name = app.desktopName;
            exec = "${launchers.${name}}/bin/${commandName name app} %U";
            inherit (app) icon categories;
            mimeType = app.mimeTypes;
            startupNotify = true;
            settings = lib.optionalAttrs (app.startupWMClass != null) {
              StartupWMClass = app.startupWMClass;
            };
          }
        ) programs;
        programs.firefox.profiles.vpn = lib.mkIf
          (programs ? firefox && programs.firefox.mode == "separate") {
            id = 1;
            settings = config.programs.firefox.profiles.default.settings // {
              "network.trr.mode" = 5;
              "widget.wayland.application_id" = "firefox-vpn";
            };
          };
      };
    })
  ];
}
