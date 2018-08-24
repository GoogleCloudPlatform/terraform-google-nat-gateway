// External data source to fetch latest regional versions (beta).
// Use this until this issue is resolved: https://github.com/terraform-providers/terraform-provider-google/issues/1937
data "external" "container-regional-versions-beta" {
  program = ["${path.module}/get_server_config_beta.sh"]

  query = {
    region = "${var.region}"
  }
}
