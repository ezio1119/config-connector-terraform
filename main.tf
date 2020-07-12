variable "project" {
  description = "自分のプロジェクトID"
  type        = string
  default     = "sample-282907"
}

provider "google" {
  project = var.project
}

provider "google-beta" {
  project = var.project
}

locals {
  services = [
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
  ]
}

resource "google_project_service" "sample_services" {
  for_each = toset(local.services)
  service  = each.value

  disable_dependent_services = true
}

resource "google_container_cluster" "sample_cluster" {
  provider = google-beta
  name     = "sample-cluster"

  location                 = "us-central1"
  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Config Connectorが対応してるバージョンならなんでもおk
  release_channel {
    channel = "REGULAR"
  }

  # Config Connectorのアドオンを追加
  addons_config {
    config_connector_config {
      enabled = true
    }
  }

  #  Workload Identityの設定
  workload_identity_config {
    identity_namespace = "${var.project}.svc.id.goog"
  }
}

resource "google_container_node_pool" "sample_nodes" {
  name       = "sample-node-pool"
  location   = "us-central1"
  cluster    = google_container_cluster.sample_cluster.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "g1-small"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}