variable "hcloud_token" {
  sensitive = true
}

variable "ssh_key" {
  description = "SSH key used to connect to the nodes"
  type        = string
}

variable "location" {
  description = "Cluster location"
  type        = string
}

variable "master_count" {
  description = "Number of master nodes to provition"
  type        = number
  default     = 1
}

variable "master_server_type" {
  description = "Master server type"
  type        = string
}

variable "worker_count" {
  description = "Number of worker nodes to provition"
  type        = number
  default     = 1
}

variable "worker_server_type" {
  description = "Worker server type"
  type        = string
}
