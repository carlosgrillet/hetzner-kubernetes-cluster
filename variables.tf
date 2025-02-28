variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "ssh_key" {
  description = "Path to the SSH key used to connect to the nodes"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Cluster location"
  type        = string
  validation {
    condition     = contains(["fsn1", "hel1", "nbg1", "sin", "ash", "hil"], var.location)
    error_message = "The location must be one of 'fsn1', 'hel1', 'nbg1' 'sin', 'ash', 'hil'."
  }
}

variable "master_count" {
  description = "Number of master nodes to provision"
  type        = number
  default     = 1
  validation {
    condition     = var.master_count >= 1
    error_message = "The number of master nodes must be at least 1"
  }
  
}

variable "master_server_type" {
  description = "Master server type"
  type        = string
  default     = "cx22"
}

variable "worker_count" {
  description = "Number of worker nodes to provision"
  type        = number
  default     = 1
  validation {
    condition     = var.worker_count >= 0
    error_message = "The number of worker nodes must be equal or greather than 0"
  }
}

variable "worker_server_type" {
  description = "Worker server type"
  type        = string
  default     = "cx22"
}
