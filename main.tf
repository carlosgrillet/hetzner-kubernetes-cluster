provider "hcloud" {
  token = var.hcloud_token
}

# Networking
resource "hcloud_network" "cluster_network" {
  name     = "k8s-cluster"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "cluster_subnet" {
  type         = "cloud"
  network_id   = hcloud_network.cluster_network.id
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

resource "hcloud_firewall" "cluster_firewall" {
  name = "cluster-firewall"
  # allow ssh connections
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  # allow cluster API connections
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "6443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

# SSH key
resource "hcloud_ssh_key" "cluster_ssh_key" {
  name       = "cluster-key"
  public_key = file(var.ssh_key)
}

# Placement groups
resource "hcloud_placement_group" "masters_area" {
  name = "masters-area"
  type = "spread"
  labels = {
    nodeType = "masters"
  }
}

resource "hcloud_placement_group" "workers_area" {
  name = "workers-area"
  type = "spread"
  labels = {
    nodeType = "workers"
  }
}


# Master node creation
resource "hcloud_server" "masters" {
  count              = var.master_count
  name               = "k8s-master-${count.index + 1}"
  image              = "ubuntu-24.04"
  location           = var.location
  server_type        = var.master_server_type
  placement_group_id = hcloud_placement_group.masters_area.id
  firewall_ids       = [hcloud_firewall.cluster_firewall.id]
  ssh_keys           = [hcloud_ssh_key.cluster_ssh_key.id]
  depends_on         = [hcloud_network_subnet.cluster_subnet]
  labels             = { nodeType : "master" }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.cluster_network.id
    ip         = "10.0.1.${count.index + 1}"
  }
}

# Workers nodes creation
resource "hcloud_server" "workers" {
  count              = var.worker_count
  name               = "k8s-worker-${count.index + 1}"
  image              = "ubuntu-24.04"
  location           = var.location
  server_type        = var.worker_server_type
  placement_group_id = hcloud_placement_group.workers_area.id
  firewall_ids       = [hcloud_firewall.cluster_firewall.id]
  ssh_keys           = [hcloud_ssh_key.cluster_ssh_key.id]
  depends_on         = [hcloud_network_subnet.cluster_subnet]
  labels             = { nodeType : "worker" }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.cluster_network.id
    ip         = "10.0.1.${count.index + 11}"
  }

}

output "master_public_ipv4" {
  description = "The public IPv4 address of the master node."
  value       = [for master in hcloud_server.masters : master.ipv4_address]
}

output "worker_public_ipv4" {
  description = "The public IPv4 addresses of the Kubernetes worker nodes."
  value       = [for worker in hcloud_server.workers : worker.ipv4_address]
}

resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/ansible/hosts"
  file_permission = "664"
  content         = <<EOL
[masters]
%{for i, ip in hcloud_server.masters.*.ipv4_address~}
master${i} ansible_host=${ip} ansible_user=root
%{endfor}
[workers]
%{for i, ip in hcloud_server.workers.*.ipv4_address~}
worker${i} ansible_host=${ip} ansible_user=root
%{endfor}
EOL
}

resource "local_file" "ansible_variables" {
  filename        = "${path.module}/ansible/playbooks/group_vars/masters.yml"
  file_permission = "664"
  content         = <<EOL
hcloud_token: ${var.hcloud_token}
hcloud_network: ${hcloud_network.cluster_network.id}
location: ${var.location}
EOL
}
