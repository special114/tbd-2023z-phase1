variable "project_name" {
  type        = string
  description = "Project name"
}

variable "region" {
  type        = string
  default     = "europe-west1"
  description = "GCP region"
}

variable "subnet" {
  type        = string
  description = "VPC subnet used for deployment"
}

variable "machine_type" {
  type        = string
  default     = "e2-medium"
  description = "Machine type to use for both worker and master nodes"
}

variable "image_version" {
  type    = string
  default = "2.1.27-ubuntu20"
}

variable "worker_nodes_num" {
  type        = number
  default     = 2
  description = "The number of worker nodes for the Dataproc cluster"
}

variable "preemptible_instances_num" {
  type        = number
  description = "The number of preemptible spot instances in Dataproc cluster"
  default     = 0
}