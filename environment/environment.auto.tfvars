### Example Input Values

# google_billing_account = ""
# google_org_id          = ""
# google_project_base    = ""

skip_delete = true # Set to true for reusable environments

metadata = {
  product       = "tf_module_testing"
  component     = "terraform-gcp-project"
  project_name  = "module_testing"
  env           = "tst"
  location      = "West US 2"
  version       = "1.0.0.199"
  cost_center   = "1234567890"
  department    = "Hosted Solutions"
  account_owner = "John Doe"
}

google_region = {
  single = "us-west2"
  multi  = "US"
}

kube_cluster_prefix         = "gke-devops"
kube_cluster_version        = "1.15"
kube_nodepool_disk_size     = "50"
kube_nodepool_instance_type = "n1-standard-2"

shared_image_project = "shared-ops"

jenkins_instance_type  = "n1-standard-1"
jenkins_data_disk_size = "10"

helm_chart_version = ""

prometheus_helm_chart_version = ""
grafana_adminuser             = "Grafana-Admin"
grafana_adminpassword         = "T31emetry!"
