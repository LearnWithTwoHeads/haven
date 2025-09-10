resource "hcloud_network" "private_network" {
  name     = "kubernetes-cluster"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "private_network_subnet" {
  type         = "cloud"
  network_id   = hcloud_network.private_network.id
  network_zone = "us-east"
  ip_range     = "10.0.1.0/24"
}

output "network_id" {
  value = hcloud_network.private_network.id
}

resource "hcloud_ssh_key" "ssh_key" {
  name       = "my-ssh-key"
  public_key = var.ssh_public_key
}

resource "hcloud_server" "master_node" {
  name        = "kubernetes-master-node"
  image       = "ubuntu-24.04"
  server_type = "cpx31"
  location    = "ash"

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.private_network.id
    # IP Used by the master node, needs to be static
    # Here the worker nodes will use 10.0.1.1 to communicate with the master node
    ip         = "10.0.1.1"
  }

  ssh_keys = [hcloud_ssh_key.ssh_key.id]

  depends_on = [hcloud_network_subnet.private_network_subnet]
}

resource "hcloud_server" "worker_nodes" {
  count = 2
  
  # The name will be worker-node-0, worker-node-1, worker-node-2...
  name        = "kubernetes-worker-node-${count.index}"
  image       = "ubuntu-24.04"
  server_type = "cpx31"
  location    = "ash"

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.private_network.id
    ip         = "10.0.1.${count.index + 2}"
  }

  ssh_keys = [hcloud_ssh_key.ssh_key.id]

  depends_on = [hcloud_network_subnet.private_network_subnet, hcloud_server.master_node]
}
