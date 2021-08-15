locals {
  bin_dir  = module.setup_clis.bin_dir
  layer = "services"
  yaml_dir = "${path.cwd}/.tmp/console-link-job"
  name = "console-link-job"
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}

module "service_account" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-service-account.git?ref=v1.3.1"

  gitops_config = var.gitops_config
  git_credentials = var.git_credentials
  namespace = var.namespace
  name = "console-link-job"
  server_name = var.server_name
}

module "rbac" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-rbac.git?ref=v1.6.1"

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

resource null_resource setup_gitops {
  depends_on = [null_resource.create_yaml]

  provisioner "local-exec" {
    command = "${local.bin_dir}/igc gitops-module '${local.name}' -n '${var.namespace}' --contentDir '${local.yaml_dir}' --serverName '${var.server_name}' -l '${local.layer}'"

    environment = {
      GIT_CREDENTIALS = yamlencode(var.git_credentials)
      GITOPS_CONFIG   = yamlencode(var.gitops_config)
    }
  }
}
