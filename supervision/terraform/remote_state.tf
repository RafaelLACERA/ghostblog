# Lecture du state persistant (VPC, subnets, security group supervision) gere
# dans app/terraform/persistent/. Ce state ne lit PAS le state "app"
# (instances Ghost) : la supervision doit garder un cycle de vie totalement
# independant, y compris pendant un destroy_app_infra/deploy_app_infra de
# test - sinon elle cesserait d'exister exactement quand on a besoin
# d'observer une recreation d'instance. Les IP privees app/staging a scraper
# sont recuperees au niveau du job Ansible (curl+jq sur l'API du state
# "app"), pas ici, precisement pour ne pas creer cette dependance dure.
data "terraform_remote_state" "data" {
  backend = "http"

  config = {
    address  = "${var.gitlab_api_url}/projects/${var.gitlab_project_id}/terraform/state/app-data"
    username = "gitlab-ci-token"
    password = var.gitlab_ci_job_token
  }

  lifecycle {
    postcondition {
      condition     = try(self.outputs.public_subnet_id, null) != null && try(self.outputs.supervision_security_group_id, null) != null
      error_message = "Le state 'app-data' est vide, inexistant, ou ne contient pas encore le security group supervision. Lancer/relancer deploy_data avant deploy_supervision."
    }
  }
}
