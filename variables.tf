variable "project_name" {
  type        = string
  description = "Project name"
}

variable "region" {
  type        = string
  default     = "europe-west1"
  description = "GCP region"
}

variable "ai_notebook_instance_owner" {
  type        = string
  description = "Vertex AI workbench owner"
}

variable "jupyterlab_machine_type" {
  type        = string
  description = "The machine type for JupyterLab"
  default     = "e2-standard-2"
}

variable "dataproc_machine_type" {
  type        = string
  description = "The machine type for the Dataproc"
  default     = "e2-standard-2"
}

variable "dataproc_worker_nodes_num" {
  type        = number
  description = "The number of worker nodes for the Dataproc cluster"
  default     = 2
}

variable "dataproc_preemptible_nodes_num" {
  type        = number
  description = "The number of preemptible spot instances in Dataproc cluster"
  default     = 0
}