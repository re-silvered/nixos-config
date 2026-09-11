{ lib, pkgs, ... }:

let
  secrets = import /etc/nixos/secrets/virtualisation.nix; # yeah lemme commit these onto a public repo
  inherit (secrets) identity;
in
{
  nixpkgs.overlays = lib.mkAfter [
    (final: prev: {
      qemu-stealth-intel = prev.qemu-stealth-intel.override {
        edidManufacturer = identity.edid.manufacturer;
        edidSerial = identity.edid.serial;
        edidProductCode = identity.edid.productCode;
        edidDpi = identity.edid.dpi;
        edidWeek = identity.edid.week;
        edidYear = identity.edid.year;
        edidResX = identity.edid.resolution.x;
        edidResY = identity.edid.resolution.y;

        diskModel = identity.disk.model;
        diskSerial = identity.disk.serial;
        opticalModel = identity.disk.opticalModel;
        scsiVendor = identity.disk.scsiVendor;
        scsiTargetProduct = identity.disk.scsiTargetProduct;

        acpiOemId = identity.acpiOem.id;
        acpiOemTableId = identity.acpiOem.tableId;
      };

      smbios-stealth-tables = prev.smbios-stealth-tables.override {
        cacheL1 = 544;
        cacheL2 = 20480;
        cacheL3 = 24576;
        cacheAssocL1 = 8;
        cacheAssocL2 = 9;
        cacheAssocL3 = 8;
        cacheEcc = 3;
      };

      libtpms-stealth = prev.libtpms.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          if grep -Fq '\"manufacturer\":\"id:00001014\"' src/tpm_tpm2_interface.c; then
            sed -i 's/\\"manufacturer\\":\\"id:00001014\\"/\\"manufacturer\\":\\"${identity.tpm.manufacturer}\\"/g' src/tpm_tpm2_interface.c
          else
            echo "vfio-stealth: libtpms manufacturer anchor not found" >&2
            exit 1
          fi

          if grep -Fq '\"model\":\"swtpm\"' src/tpm_tpm2_interface.c; then
            sed -i 's/\\"model\\":\\"swtpm\\"/\\"model\\":\\"${identity.tpm.model}\\"/g' src/tpm_tpm2_interface.c
          else
            echo "vfio-stealth: libtpms model anchor not found" >&2
            exit 1
          fi
        '';
      });

      swtpm-stealth = prev.swtpm.override {
        libtpms = final.libtpms-stealth;
      };
    })
  ];

  users.users.silver.extraGroups = [ "libvirtd" ];
  programs.virt-manager.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu-stealth-intel;
      swtpm = {
        enable = true;
        package = pkgs.swtpm-stealth;
      };
    };
  };

  environment.systemPackages = [
    pkgs.ovmf-stealth-intel
    pkgs.smbios-stealth-tables
  ];

  virtualisation.vfio-stealth = {
    enable = true;
    cpuVendor = "intel";

    # unsupported on this Intel host.
    timing.enable = false;
    cpuidSpoof.enable = false;
    cpuidPassthrough.enable = false;

    kernelParams = {
      maxCState = 1;
      tscReliable = true;
    };

    smbios = secrets.smbios // {
      cache = {
        l1 = 544;
        l2 = 20480;
        l3 = 24576;
        assocL1 = 8;
        assocL2 = 9;
        assocL3 = 8;
        ecc = 3;
      };

    };

    aperfMperf = true;
    kvmPvEnforceCpuid = false;
    pciMmio64Mb = 65536;

    stripVirtio = true;
    spoofMac = true;
    macPrefix = secrets.macPrefix;

    hypervVendorId = secrets.hypervVendorId;
    hypervMode = "hidden";
    hypervFeatures = {
      vendor_id = true;
      relaxed = true;
      vapic = true;
      spinlocks = true;
      frequencies = true;
      vpindex = true;
      synic = true;
      stimer = true;
      reset = true;
      ipi = true;
      tlbflush = true;
      reenlightenment = true;
      runtime = true;
    };

    kernelCapabilities = {
      vendor_id = true;
      relaxed = true;
      vapic = true;
      spinlocks = true;
      frequencies = true;
      vpindex = true;
      synic = true;
      stimer = true;
      reset = true;
      ipi = true;
      tlbflush = true;
      reenlightenment = true;
      runtime = true;
    };

    acpiSsdt = {
      spoofedDevices = true;
      fakeBattery = true;
      sensorProbes = true;
    };

    edid = {
      inherit (identity.edid) manufacturer serial productCode dpi week year;
    };

    disk = {
      inherit (identity.disk) model serial opticalModel;
    };

    acpiOem = identity.acpiOem;

    cpuIdentity = secrets.cpuIdentity;

    tpm = identity.tpm // secrets.tpm;
  };
}
