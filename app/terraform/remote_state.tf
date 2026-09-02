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

  # Garde-fou : message clair si deploy_data n'a jamais ete lance, au lieu
  # d'un plantage Terraform cryptique sur un attribut manquant plus loin
  # dans ec2.tf.
  lifecycle {
    postcondition {
      condition     = self.outputs.public_subnet_id != null && self.outputs.app_security_group_id != null
      error_message = "Le state 'app-data' est vide ou inexistant. Lancer le job deploy_data avant deploy_app_infra."
    }
  }
}
