resource "talos_machine_secrets" "cluster" {
  talos_version = "v${local.talos_version}"
}

data "talos_client_configuration" "this" {
  cluster_name         = local.cluster_name
  client_configuration = talos_machine_secrets.cluster.client_configuration
  nodes                = [local.control_plane.ip]
  endpoints            = [local.control_plane.ip]
}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = local.cluster_name
  machine_type       = "controlplane"
  cluster_endpoint   = "https://${local.control_plane.ip}:6443"
  machine_secrets    = talos_machine_secrets.cluster.machine_secrets
  talos_version      = "v${local.talos_version}"
  kubernetes_version = local.kubernetes_version

  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk  = "/dev/sda"
          image = local.talos_installer_image
        }
      }
    })
  ]
}

# Generated from the cluster secrets without contacting the Kubernetes API.
# talos_machine consumes it through a write-only attribute when draining a node
# for future Talos OS upgrades.
ephemeral "talos_cluster_kubeconfig" "this" {
  cluster_name    = local.cluster_name
  endpoint        = "https://${local.control_plane.ip}:6443"
  machine_secrets = talos_machine_secrets.cluster.machine_secrets
}

# # Worker machine configuration
# data "talos_machine_configuration" "worker" {
#   cluster_name     = "talos-homelab"
#   machine_type     = "worker"
#   cluster_endpoint = "https://10.0.0.1:6443"
#   machine_secrets  = talos_machine_secrets.cluster.machine_secrets
#   talos_version    = "v1.12.6"
# }

resource "talos_machine" "control_plane" {
  depends_on = [libvirt_domain.cluster_controlplane]

  node                  = local.control_plane.ip
  client_configuration  = talos_machine_secrets.cluster.client_configuration
  machine_configuration = data.talos_machine_configuration.controlplane.machine_configuration
  image                 = local.talos_installer_image
  kubeconfig_wo         = ephemeral.talos_cluster_kubeconfig.this.kubeconfig_raw

  # Let talos_cluster perform Kubernetes upgrades safely.
  ignore_kubernetes_upgrade_drift = true
}

# resource "talos_machine" "workers" {
#   for_each = local.workers
#
#   node                  = each.value.ip
#   client_configuration  = talos_machine_secrets.cluster.client_configuration
#   machine_configuration = data.talos_machine_configuration.worker.machine_configuration
#   image                 = "factory.talos.dev/installer/...:v1.13.7"
#
#   ignore_kubernetes_upgrade_drift = true
# }

resource "talos_cluster" "this" {
  depends_on = [talos_machine.control_plane]

  node                 = local.control_plane.ip
  control_plane_nodes  = [local.control_plane.ip]
  client_configuration = talos_machine_secrets.cluster.client_configuration
  kubernetes_version   = "v${local.kubernetes_version}"
}


# Bootstrap the cluster
# resource "talos_machine_bootstrap" "this" {
#   depends_on = [
#     talos_machine_configuration_apply.controlplane
#   ]
#
#   client_configuration = talos_machine_secrets.cluster.client_configuration
#   node                 = "10.0.0.10"
# }
