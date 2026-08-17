
resource "libvirt_domain" "cluster_nodes" {
  for_each = {
    for machine in local.nodes : machine.name => machine
  }

  name        = each.key
  memory      = each.value.memory
  memory_unit = "MiB"
  vcpu        = each.value.cpu
  type        = "kvm"
  running     = true

  # https://docs.siderolabs.com/talos/v1.13/platform-specific-installations/virtualized-platforms/proxmox#vm-resource-requirements
  cpu = {
    mode = "host-passthrough"
  }

  features = {
    acpi = true
  }


  os = {
    type            = "hvm"
    type_arch       = "x86_64"
    type_machine    = "q35"
    firmware        = "efi"
    loader          = "/usr/share/edk2/x64/OVMF_CODE.4m.fd"
    loader_readonly = "yes"
    loader_type     = "pflash"
    # nv_ram = {
    #   nv_ram   = "/var/lib/libvirt/qemu/nvram/homelab-cluster-controlplane.fd"
    #   template = "/usr/share/edk2/x64/OVMF_VARS.4m.fd"
    # }
    # Try the installed disk first. A fresh blank disk falls through to the
    # Talos ISO; after installation, subsequent boots use the disk directly.
    boot_devices = [
      { dev = "hd" },
      { dev = "cdrom" },
    ]
  }


  devices = {
    mem_balloon = {
      model = "none"
    }

    graphics = [
      {
        vnc = {
          auto_port = true
          listen    = "127.0.0.1"
        }
      }
    ]

    videos = [
      {
        model = {
          type    = "vga"
          primary = "yes"
          heads   = 1
          vram    = 16384 # KiB
        }
      }
    ]

    controllers = [
      {
        type  = "scsi"
        index = 0
        model = "virtio-scsi"
      }
    ]

    disks = [
      {
        device = "disk"
        source = {
          volume = {
            volume = libvirt_volume.node_install_volumes[each.key].name
            pool   = libvirt_volume.node_install_volumes[each.key].pool
          }
        }
        target = {
          dev = "sda"
          bus = "scsi"
        }
        driver = {
          name = "qemu"
          type = "qcow2"
        }
      },
      {
        device    = "cdrom"
        read_only = true
        source = {
          volume = {
            volume = libvirt_volume.talos_boot_iso.name
            pool   = libvirt_volume.talos_boot_iso.pool
          }
        }
        target = {
          dev = "sdb"
          bus = "sata"
        }
        driver = {
          name = "qemu"
          type = "raw"
        }
      }
    ]

    interfaces = [
      {
        mac = {
          address = each.value.mac
        }
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = libvirt_network.homelab_network.name
          }

        }
      }
    ]

    consoles = [
      {
        target = {
          type = "serial"
          port = "0"
        }
      }
    ]
  }
}
