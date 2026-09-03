# Lecture du state "app" (instances EC2) pour recuperer les IP publiques a
# pointer en DNS. Meme pattern que app/terraform/instances/remote_state.tf
# qui lit deja le state "app-data".
data "terraform_remote_state" "instances" {
  backend = "http"

  config = {
    address  = "${var.gitlab_api_url}/projects/${var.gitlab_project_id}/terraform/state/app"
    username = "gitlab-ci-token"
    password = var.gitlab_ci_job_token
  }

  # Garde-fou : message clair si deploy_app_infra n'a jamais ete lance, au
  # lieu d'un plantage Terraform cryptique sur un attribut manquant plus
  # loin dans records.tf. try() est indispensable ici : si le state "app"
  # est completement vide (0 ressource), self.outputs n'a aucun attribut
  # du tout, donc self.outputs.app_public_ip planterait a la lecture meme
  # de l'expression, avant que le != null ait une chance de s'executer.
  lifecycle {
    postcondition {
      condition     = try(self.outputs.app_public_ip, null) != null && try(self.outputs.staging_public_ip, null) != null
      error_message = "Le state 'app' est vide ou inexistant. Lancer le job deploy_app_infra avant deploy_dns."
    }
  }
}
