locals {
  bin_dir  = module.setup_clis.bin_dir
  layer = "services"
  yaml_dir = "${path.cwd}/.tmp/console-link-job"
  name = "console-link-job"
  application_branch = "main"
  type = "base"
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}

module "service_account" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-service-account.git?ref=v1.9.0"

  gitops_config = var.gitops_config
  git_credentials = var.git_credentials
  namespace = var.namespace
  name = "console-link-job"
  server_name = var.server_name
}

module "rbac" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-rbac.git?ref=v1.9.1"
  depends_on = [module.service_account]

  cluster_scope = true

  gitops_config = var.gitops_config
  git_credentials = var.git_credentials
  namespace = var.namespace
  label = module.service_account.name
  service_account_namespace = module.service_account.namespace
  service_account_name      = module.service_account.name
  rules = [
    {
      apiGroups = [""]
      resources = ["configmaps"]
      verbs = ["*"]
    },
    {
      apiGroups = ["apps"]
      resources = ["daemonsets"]
      verbs = ["list", "get"]
    },
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
  server_name = var.server_name
}

resource null_resource create_yaml {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.yaml_dir}' '${module.service_account.name}'"
  }
}

resource gitops_module module {
  depends_on = [null_resource.create_yaml, module.service_account]

  name = local.name
  namespace = var.namespace
  content_dir = local.yaml_dir
  server_name = var.server_name
  layer = local.layer
  type = local.type
  branch = local.application_branch
  config = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}
