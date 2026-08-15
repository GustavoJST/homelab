locals {
  cluster_name       = "talos-homelab"
  talos_version      = "1.13.7"
  kubernetes_version = "1.34.9"

  # These values identify the temporary ISO used to boot an uninstalled VM.
  # Keep them stable for existing machines; changing them only replaces the
  # boot-media volume, not the persistent node disk.
  talos_bootstrap_version      = "v1.13.7"
  talos_bootstrap_schematic_id = "d9ff89777e246792e7642abd3220a616afb4e49822382e4213a2e528ab826fe5"
  talos_boot_iso_url           = "https://factory.talos.dev/image/${local.talos_bootstrap_schematic_id}/${local.talos_bootstrap_version}/metal-amd64.iso"

  # These values describe the Talos OS that should be installed and kept
  # running. Bump talos_version (or the schematic) for an in-place OS upgrade.
  talos_schematic_id    = "d9ff89777e246792e7642abd3220a616afb4e49822382e4213a2e528ab826fe5"
  talos_installer_image = "factory.talos.dev/metal-installer/${local.talos_schematic_id}:v${local.talos_version}"

  control_plane = {
    name = "${local.cluster_name}-controlplane-1"
    mac  = "52:54:00:af:ea:d4"
    ip   = "10.0.0.10"
  }
}
