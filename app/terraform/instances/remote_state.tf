# Lecture du state persistant (VPC, subnets, security group) gere dans
# app/terraform/persistent/. Ce state (app) ne contient plus que les instances
# EC2, jetables et recreees a chaque cycle de test, sans jamais toucher au reseau.
data "terraform_remote_state" "data" {
  backend = "http"

  config = {
    address  = "${var.gitlab_api_url}/projects/${var.gitlab_project_id}/terraform/state/app-data"
    username = "gitlab-ci-token"
    password = var.gitlab_ci_job_token
  }

  # Garde-fou : message clair si deploy_data n'a jamais ete lance, au lieu
  # d'un plantage Terraform cryptique sur un attribut manquant plus loin
  # dans ec2.tf. try() est indispensable ici : si le state app-data est
  # completement vide (0 ressource), self.outputs n'a aucun attribut du
  # tout, donc self.outputs.public_subnet_id planterait a la lecture meme
  # de l'expression, avant que le != null ait une chance de s'executer.
  lifecycle {
    postcondition {
      condition     = try(self.outputs.public_subnet_id, null) != null && try(self.outputs.app_security_group_id, null) != null
      error_message = "Le state 'app-data' est vide ou inexistant. Lancer le job deploy_data avant deploy_app_infra."
    }
  }
}
