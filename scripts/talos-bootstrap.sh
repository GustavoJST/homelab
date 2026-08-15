#!/usr/bin/env bash

export CLUSTER_NAME="homelab-cluster-controlplane"
export DISK_NAME="sda"

export CONTROL_PLANE_IP=$(virsh -c qemu:///system domifaddr homelab-cluster-controlplane | egrep '/' | awk '{print $4}' | cut -d/ -f1)
# export NODE_IP=$(virsh domifaddr worker-node-1 | egrep '/' | awk '{print $4}' | cut -d/ -f1)

talosctl gen config $CLUSTER_NAME https://$CONTROL_PLANE_IP:6443 --install-disk /dev/$DISK_NAME -o configs/
talosctl apply-config --insecure --nodes $CONTROL_PLANE_IP --file configs/controlplane.yaml
# talosctl apply-config --insecure --nodes $NODE_IP --file configs/worker.yaml

sleep 20s

export TALOSCONFIG=$(realpath configs/talosconfig)
talosctl config endpoint $CONTROL_PLANE_IP
talosctl -n $CONTROL_PLANE_IP bootstrap
talosctl -n $CONTROL_PLANE_IP get members
talosctl -n $CONTROL_PLANE_IP kubeconfig $PWD/configs/kubeconfig

