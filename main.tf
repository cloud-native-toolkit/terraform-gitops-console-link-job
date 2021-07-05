locals {
  layer = "services"
  config_project = var.config_projects[local.layer]
  application_branch = "main"
  application_path = "${var.application_paths[local.layer]}/console-link-job"
}

module "service_account" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-service-account"

  config_repo = var.config_repo
  config_token = var.config_token
  config_paths = var.config_paths
  config_projects = var.config_projects
  application_repo = var.application_repo
  application_token = var.application_token
  application_paths = var.application_paths
  namespace = var.namespace
  name = "console-link-job"
}

module "rbac" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-rbac"

  cluster_scope = true

  config_repo = var.config_repo
  config_token = var.config_token
  config_paths = var.config_paths
  config_projects = var.config_projects
  application_repo = var.application_repo
  application_token = var.application_token
  application_paths = var.application_paths
  namespace = var.namespace
  service_account_namespace = module.service_account.namespace
  service_account_name      = module.service_account.name
  rules = [
    {
      apiGroups = ["route.openshift.io"]
      resources = ["routes"]
      verbs = ["list", "get"]
    }, {
      apiGroups = ["console.openshift.io"]
      resources = ["consolelinks"]
      verbs = ["*"]
    }
  ]
}

resource null_resource setup_application {
  provisioner "local-exec" {
    command = "${path.module}/scripts/setup-application.sh '${var.application_repo}' '${local.application_path}' '${module.service_account.namespace}' '${module.service_account.name}'"

    environment = {
      TOKEN = var.application_token
    }
  }
}

resource null_resource setup_argocd {
  depends_on = [null_resource.setup_application]
  provisioner "local-exec" {
    command = "${path.module}/scripts/setup-argocd.sh '${var.config_repo}' '${var.config_paths[local.layer]}' '${local.config_project}' '${var.application_repo}' '${local.application_path}' '${module.rbac.service_account_namespace}' '${local.application_branch}'"

    environment = {
      TOKEN = var.config_token
    }
  }
}
