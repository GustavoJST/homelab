resource "libvirt_network" "homelab_network" {
  name      = "homelab"
  autostart = true
  forward = {
    mode = "nat"
    nat  = {}
  }
  bridge = {
    name = "talos-bridge"
    stp  = "on"
  }
  ips = [
    {
      family  = "ipv4"
      address = "10.0.0.1"
      netmask = "255.255.255.0"
      dhcp = {
        ranges = [
          {
            start = "10.0.0.40"
            end   = "10.0.0.254"
            lease = {
              expiry = 3600
              unit   = "seconds"
            }
          }
        ]
      }
    }
  ]

  # DHCP reservations are updated live below. Keep changes made by net-update
  # from making the provider replace the entire network on the next plan.
  lifecycle {
    ignore_changes = [ips[0].dhcp.hosts]
  }
}

# The libvirt provider replaces a network when its DHCP hosts change. Manage
# each reservation with libvirt's live-update API instead so existing guests
# remain connected while nodes are added, removed, or updated.
resource "terraform_data" "dhcp_host" {
  for_each = {
    for node in local.nodes : node.name => node
  }

  input = {
    libvirt_uri = "qemu:///system"
    network     = libvirt_network.homelab_network.name
    mac         = each.value.mac
    ip          = each.value.ip
    name        = each.value.name
  }

  triggers_replace = [
    each.value.mac,
    each.value.ip,
    each.value.name,
  ]

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      reservation_xml="<host mac='$HOMELAB_DHCP_MAC' name='$HOMELAB_DHCP_NAME' ip='$HOMELAB_DHCP_IP'/>"
      network_xml="$(virsh -c "$HOMELAB_LIBVIRT_URI" net-dumpxml "$HOMELAB_NETWORK")"

      if grep -Fq "mac='$HOMELAB_DHCP_MAC'" <<<"$network_xml"; then
        virsh -c "$HOMELAB_LIBVIRT_URI" net-update "$HOMELAB_NETWORK" \
          modify ip-dhcp-host "$reservation_xml" --live --config
      else
        virsh -c "$HOMELAB_LIBVIRT_URI" net-update "$HOMELAB_NETWORK" \
          add-last ip-dhcp-host "$reservation_xml" --live --config
      fi
    EOT

    interpreter = ["/bin/bash", "-c"]

    environment = {
      HOMELAB_LIBVIRT_URI = self.input.libvirt_uri
      HOMELAB_NETWORK     = self.input.network
      HOMELAB_DHCP_MAC    = self.input.mac
      HOMELAB_DHCP_IP     = self.input.ip
      HOMELAB_DHCP_NAME   = self.input.name
    }
  }

  provisioner "local-exec" {
    when = destroy

    command = <<-EOT
      set -euo pipefail

      reservation_xml="<host mac='$HOMELAB_DHCP_MAC' name='$HOMELAB_DHCP_NAME' ip='$HOMELAB_DHCP_IP'/>"
      network_xml="$(virsh -c "$HOMELAB_LIBVIRT_URI" net-dumpxml "$HOMELAB_NETWORK")"

      if grep -Fq "mac='$HOMELAB_DHCP_MAC'" <<<"$network_xml"; then
        virsh -c "$HOMELAB_LIBVIRT_URI" net-update "$HOMELAB_NETWORK" \
          delete ip-dhcp-host "$reservation_xml" --live --config
      fi
    EOT

    interpreter = ["/bin/bash", "-c"]

    environment = {
      HOMELAB_LIBVIRT_URI = self.input.libvirt_uri
      HOMELAB_NETWORK     = self.input.network
      HOMELAB_DHCP_MAC    = self.input.mac
      HOMELAB_DHCP_IP     = self.input.ip
      HOMELAB_DHCP_NAME   = self.input.name
    }
  }
}
