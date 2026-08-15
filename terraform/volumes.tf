resource "libvirt_volume" "talos_boot_iso" {
  name = "talos-${local.talos_bootstrap_version}-${substr(local.talos_bootstrap_schematic_id, 0, 12)}-metal-amd64.iso"
  pool = "default"

  target = {
    format = {
      type = "iso"
    }
  }

  create = {
    content = {
      url = local.talos_boot_iso_url
    }
  }
}


# resource "libvirt_volume" "talos_base" {
#   name = "talos-base.qcow2"
#   pool = "default"
#
#   target = {
#     format = {
#       type = "qcow2"
#     }
#   }
#
#   create = {
#     content = {
#       url = "https://factory.talos.dev/image/d9ff89777e246792e7642abd3220a616afb4e49822382e4213a2e528ab826fe5/v1.13.7/metal-amd64.qcow2"
#     }
#   }
#
#   # lifecycle {
#   #   prevent_destroy = true
#   # }
# }
#
# resource "libvirt_volume" "controlplane_disk" {
#   name     = "controlplane-1-disk.qcow2"
#   pool     = "default"
#   capacity = 20 * 1024 * 1024 * 1024 # 20 GB
#
#   target = {
#     format = {
#       type = "qcow2"
#     }
#   }
#
#   backing_store = {
#     path = libvirt_volume.talos_base.id
#     format = {
#       type = "qcow2"
#     }
#   }
#
#   # lifecycle {
#   #   prevent_destroy = true
#   # }
# }

# New persistent disk for the ISO-based installation flow. It has no backing
# store, so changing Talos boot media or the desired OS version cannot replace
# it or invalidate a QCOW2 backing chain.
resource "libvirt_volume" "controlplane_install_disk" {
  name     = "controlplane-1-install-disk.qcow2"
  pool     = "default"
  capacity = 20 * 1024 * 1024 * 1024 # 20 GB

  target = {
    format = {
      type = "qcow2"
    }
  }
}
