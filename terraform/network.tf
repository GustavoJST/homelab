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
        hosts = [
          for node in local.nodes : {
            mac  = node.mac
            ip   = node.ip
            name = node.name
          }
        ]
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
}