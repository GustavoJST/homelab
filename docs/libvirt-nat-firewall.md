# Libvirt NAT guest has no outbound network access

## Symptom

A VM attached to a libvirt NAT network receives a valid IP address, gateway,
and DNS server, but connections outside the host time out. For example, Talos
may report IPv4 NTP timeouts or fail to connect to `discovery.talos.dev:443`.

Typical signs are:

- DHCP and DNS through the libvirt bridge work.
- The host can reach the VM.
- The VM has a valid IPv4 default route.
- Packets reach the libvirt bridge (for example, `virbr1`) but do not leave the
  host's physical interface.

IPv6 `network is unreachable` messages are a separate and expected symptom if
the libvirt network is configured for IPv4 only.

## Cause

Recent libvirt versions prefer their native nftables firewall backend. Other
software running on the host can manage the global forwarding firewall at the
same time. In this case, Docker was active with its `iptables+firewalld`
backend and installed a dropping policy in the host's `FORWARD` path.

This can affect a libvirt VM even though the VM and Terraform project do not
use Docker: firewall forwarding rules apply to the entire host. An accept rule
in libvirt's separate nftables table cannot override a drop performed by
another netfilter table or chain.

Useful checks:

```bash
sudo iptables -L FORWARD -n -v
sudo nft list ruleset
sysctl net.ipv4.ip_forward
virsh -c qemu:///system net-dumpxml homelab
```

## Fix

Configure libvirt to use its iptables backend so its forwarding rules coexist
correctly with the host's existing iptables-compatible rules.

Edit `/etc/libvirt/network.conf` and set:

```ini
firewall_backend = "iptables"
```

Then restart the libvirt network service. On this host, which uses the legacy
monolithic daemon:

```bash
sudo systemctl restart libvirtd
```

On a host using modular libvirt daemons, restart `virtnetworkd` instead:

```bash
sudo systemctl restart virtnetworkd
```

Using the `iptables` backend here does not necessarily mean switching the
kernel back to legacy iptables; on modern distributions, the iptables commands
usually use the nftables compatibility layer. It simply makes libvirt install
its rules in a form that interoperates with the other host firewall rules.

Avoid using `iptables -P FORWARD ACCEPT` as a permanent fix. That changes the
host-wide forwarding policy and is broader than configuring libvirt's scoped
rules correctly.

References:

- [Libvirt virtual network nftables compatibility notes](https://fedoraproject.org/wiki/Changes/LibvirtVirtualNetworkNFTables#Known_issue:_docker)
- [Docker packet filtering and forwarding behavior](https://docs.docker.com/engine/network/packet-filtering-firewalls/)
