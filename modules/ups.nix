# Got too big for hardware.nix ...
{ lib, config, ... }:

{
  options.my.ups.enable = lib.mkEnableOption "UPS support";

  config = lib.mkIf config.my.ups.enable {
    power.ups = {
      enable = true;
      mode = "standalone";

      ups."UPS-1" = {
        driver = "usbhid-ups";
        port = "auto";
      };
      users."nut-admin" = {
        passwordFile = "/etc/nixos/secrets/nut-password";
        upsmon = "primary";
      };

      upsmon.monitor."UPS-1" = {
        system = "UPS-1@localhost";
        powerValue = 1;

        user = "nut-admin";
        passwordFile = "/etc/nixos/secrets/nut-password";
        type = "primary";
      };
    };
  };
}
