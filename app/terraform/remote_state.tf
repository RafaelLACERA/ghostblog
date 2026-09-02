# Lecture du state persistant (VPC, subnets, security group) gere dans
# app/terraform-data/. Ce state (app) ne contient plus que les instances EC2,
# jetables et recreees a chaque cycle de test, sans jamais toucher au reseau.
data "terraform_remote_state" "data" {
  backend = "http"

  config = {
    address  = "${var.gitlab_api_url}/projects/${var.gitlab_project_id}/terraform/state/app-data"
    username = "gitlab-ci-token"
    password = var.gitlab_ci_job_token
  }
}
