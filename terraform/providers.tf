terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.12.0-alpha.5"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

provider "talos" {}