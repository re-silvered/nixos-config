{ config, lib, pkgs, inputs, ... }:

let
  secrets = import /etc/nixos/secrets/virtualisation.nix; # yeah lemme commit these onto a public repo
  inherit (secrets) identity;
  inherit (secrets) smbios;
  vm = secrets.vm;
  escapeXml = lib.strings.escapeXML;

  stealthFeatures = inputs.vfio-stealth.lib.mkStealthFeatures {
    inherit smbios;
    acpiTables = pkgs.acpi-ssdt-stealth;
    smbiosTables = pkgs.smbios-stealth-tables;
    vmUuid = vm.uuid;
    inherit (config.virtualisation.vfio-stealth)
      acpiSsdt
      aperfMperf
      stripVirtio
      hypervVendorId
      hypervMode
      kvmPvEnforceCpuid
      pciMmio64Mb
      hypervFeatures
      kernelCapabilities
      ;
  };
  rawQemuArgs = stealthFeatures.qemuArgs secrets.cpuIdentity;
  escapeQemuSmbios = lib.replaceStrings [ "," ] [ ",," ];
  qemuArgs =
    lib.flatten (
      lib.imap0 (
        index: arg:
        if
          lib.hasPrefix "type=3," arg
          || (
            index + 1 < builtins.length rawQemuArgs
            && lib.hasPrefix "type=3," (builtins.elemAt rawQemuArgs (index + 1))
          )
        then
          [ ]
        else
          [ arg ]
      ) rawQemuArgs
    )
    ++ [
      "-smbios"
      "type=3,manufacturer=${escapeQemuSmbios smbios.manufacturer},version=${escapeQemuSmbios smbios.baseBoardVersion},serial=${escapeQemuSmbios smbios.serial},asset=${escapeQemuSmbios smbios.baseBoardAsset},sku=${escapeQemuSmbios smbios.product}"
    ];
  qemuArgsXml = lib.concatMapStringsSep "\n    " (arg: ''<qemu:arg value='${escapeXml arg}'/>'') qemuArgs;
  diskImage = "/var/lib/libvirt/images/windows11.qcow2";
  windowsIso = "/var/lib/libvirt/iso/windows11.iso";
  windows11Xml = pkgs.writeText "windows11-domain.xml" ''
    <domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
      <name>${escapeXml vm.name}</name>
      <uuid>${escapeXml vm.uuid}</uuid>
      <memory unit='MiB'>${toString vm.memoryMiB}</memory>
      <currentMemory unit='MiB'>${toString vm.memoryMiB}</currentMemory>
      <memoryBacking>
        <nosharepages/>
      </memoryBacking>
      <vcpu placement='static'>${toString vm.vcpus}</vcpu>
      <os>
        <type arch='x86_64' machine='q35'>hvm</type>
        <loader readonly='yes' type='pflash'>${pkgs.ovmf-stealth-intel.fd}/FV/OVMF_CODE.ms.fd</loader>
        <nvram template='${pkgs.ovmf-stealth-intel.fd}/FV/OVMF_VARS.ms.fd'>/var/lib/libvirt/qemu/nvram/windows11_VARS.fd</nvram>
        <boot dev='cdrom'/>
        <boot dev='hd'/>
        <smbios mode='sysinfo'/>
      </os>
      <sysinfo type='smbios'>
        <bios>
          <entry name='vendor'>${escapeXml smbios.biosVendor}</entry>
          <entry name='version'>${escapeXml smbios.biosVersion}</entry>
          <entry name='date'>${escapeXml smbios.biosDate}</entry>
          <entry name='release'>${escapeXml smbios.biosRelease}</entry>
        </bios>
        <system>
          <entry name='manufacturer'>${escapeXml smbios.manufacturer}</entry>
          <entry name='product'>${escapeXml smbios.product}</entry>
          <entry name='version'>${escapeXml smbios.baseBoardVersion}</entry>
          <entry name='serial'>${escapeXml smbios.serial}</entry>
          <entry name='uuid'>${escapeXml vm.uuid}</entry>
          <entry name='family'>To be filled by O.E.M.</entry>
        </system>
        <baseBoard>
          <entry name='manufacturer'>${escapeXml smbios.manufacturer}</entry>
          <entry name='product'>${escapeXml smbios.product}</entry>
          <entry name='version'>${escapeXml smbios.baseBoardVersion}</entry>
          <entry name='serial'>${escapeXml smbios.baseBoardSerial}</entry>
          <entry name='asset'>${escapeXml smbios.baseBoardAsset}</entry>
          <entry name='location'>${escapeXml smbios.baseBoardLocation}</entry>
        </baseBoard>
      </sysinfo>
      <features>
        <acpi/>
        <apic/>
        <smm state='on'/>
        <kvm>
          <hidden state='on'/>
          <hint-dedicated state='on'/>
          <poll-control state='on'/>
        </kvm>
        <vmport state='off'/>
      </features>
      <cpu mode='host-passthrough' check='none' migratable='on'>
        <topology sockets='1' dies='1' cores='5' threads='2'/>
        <feature policy='disable' name='hypervisor'/>
        <feature policy='optional' name='topoext'/>
        <feature policy='optional' name='invtsc'/>
      </cpu>
      <clock offset='localtime'>
        <timer name='rtc' tickpolicy='catchup'/>
        <timer name='pit' tickpolicy='delay'/>
        <timer name='hpet' present='yes'/>
        <timer name='kvmclock' present='no'/>
        <timer name='tsc' present='yes' mode='native'/>
      </clock>
      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>destroy</on_crash>
      <devices>
        <emulator>${pkgs.qemu-stealth-intel}/bin/qemu-system-x86_64</emulator>
        <disk type='file' device='disk'>
          <driver name='qemu' type='qcow2' cache='none' io='native' discard='unmap'/>
          <source file='${diskImage}'/>
          <target dev='sda' bus='sata'/>
          <serial>${escapeXml identity.disk.serial}</serial>
        </disk>
        <disk type='file' device='cdrom'>
          <driver name='qemu' type='raw'/>
          <source file='${windowsIso}' startupPolicy='mandatory'/>
          <target dev='sdc' bus='sata'/>
          <readonly/>
        </disk>
        <interface type='network'>
          <mac address='${escapeXml vm.macAddress}'/>
          <source network='default'/>
          <model type='e1000e'/>
        </interface>
        <tpm model='tpm-crb'>
          <backend type='emulator' version='2.0'/>
        </tpm>
        <hostdev mode='subsystem' type='pci' managed='yes'>
          <source>
            <address domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>
          </source>
        </hostdev>
        <hostdev mode='subsystem' type='pci' managed='yes'>
          <source>
            <address domain='0x0000' bus='0x03' slot='0x00' function='0x1'/>
          </source>
        </hostdev>
        ${lib.optionalString vm.installationMode ''
          <graphics type='spice' autoport='yes'>
            <listen type='address' address='127.0.0.1'/>
          </graphics>
          <video>
            <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1' primary='yes'/>
          </video>
          <channel type='spicevmc'>
            <target type='virtio' name='com.redhat.spice.0'/>
          </channel>
          <input type='tablet' bus='usb'/>
          <input type='mouse' bus='ps2'/>
          <input type='keyboard' bus='ps2'/>
        ''}
        <memballoon model='none'/>
      </devices>
      <qemu:commandline>
        ${qemuArgsXml}
      </qemu:commandline>
    </domain>
  '';
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

  systemd.services.libvirt-windows11-volume = {
    description = "Create the Windows 11 libvirt volume";
    wantedBy = [ "multi-user.target" ];
    before = [ "libvirt-windows11-domain.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [ ! -e ${diskImage} ]; then
        ${pkgs.coreutils}/bin/mkdir -p /var/lib/libvirt/images
        ${pkgs.qemu-stealth-intel}/bin/qemu-img create -f qcow2 \
          -o compat=1.1,lazy_refcounts=on ${diskImage} ${toString vm.diskGiB}G
      elif [ ! -f ${diskImage} ]; then
        echo "${diskImage} exists but is not a regular file" >&2
        exit 1
      fi
    '';
  };

  # keep it available for Windows
  systemd.services.libvirt-default-network = {
    description = "Start libvirt's default NAT network";
    wantedBy = [ "multi-user.target" ];
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.libvirt}/bin/virsh -c qemu:///system net-autostart default
      if ! ${pkgs.libvirt}/bin/virsh -c qemu:///system net-info default | ${pkgs.gnugrep}/bin/grep -q 'Active:.*yes'; then
        ${pkgs.libvirt}/bin/virsh -c qemu:///system net-start default
      fi
    '';
  };

  # This is deliberately idempotent
  systemd.services.libvirt-windows11-domain = {
    description = "Define the Windows 11 passthrough VM";
    wantedBy = [ "multi-user.target" ];
    after = [
      "libvirtd.service"
      "libvirt-default-network.service"
      "libvirt-windows11-volume.service"
    ];
    requires = [
      "libvirtd.service"
      "libvirt-default-network.service"
      "libvirt-windows11-volume.service"
    ];
    unitConfig = {
      ConditionPathExists = windowsIso;
      ConditionPathExistsGlob = "/sys/kernel/iommu_groups/*";
    };
    restartIfChanged = true;
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.libvirt}/bin/virsh -c qemu:///system define ${windows11Xml}
    '';
  };
}
