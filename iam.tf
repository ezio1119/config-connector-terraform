locals {
  sample_config_connector_roles = [
    "roles/editor",
    # プロジェクトレベルのポリシーを設定する場合必要
    # "roles/iam.securityAdmin",
  ]
}

variable "k8s_namespace" {
  description = "default"
  type        = string
  default     = "default"
}


resource "google_service_account" "sample_config_connector_account" {
  account_id   = "sample-config-conn-account"
  display_name = "Sample Config Connector Account."
}

resource "google_project_iam_member" "sample_config_connector_iam" {
  for_each = toset(local.sample_config_connector_roles)
  role     = each.value
  member   = "serviceAccount:${google_service_account.sample_config_connector_account.email}"
}

resource "google_service_account_iam_member" "sample_config_connector_bind" {
  service_account_id = google_service_account.sample_config_connector_account.name
  role               = "roles/iam.workloadIdentityUser"

  member = "serviceAccount:${var.project}.svc.id.goog[cnrm-system/cnrm-controller-manager-${var.k8s_namespace}]"
}