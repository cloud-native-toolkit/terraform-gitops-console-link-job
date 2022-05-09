locals {
  bin_dir  = module.setup_clis.bin_dir
  layer = "services"
  yaml_dir = "${path.cwd}/.tmp/console-link-job"
  name = "console-link-job"
  application_branch = "main"
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}

module "service_account" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-service-account.git"

  gitops_config = var.gitops_config
  git_credentials = var.git_credentials
  namespace = var.namespace
  name = "console-link-job"
  server_name = var.server_name
}

module "rbac" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-rbac.git"
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

/*resource null_resource setup_gitops {
  depends_on = [null_resource.create_yaml, module.service_account, module.rbac]

  provisioner "local-exec" {
    command = "${local.bin_dir}/igc gitops-module '${local.name}' -n '${var.namespace}' --contentDir '${local.yaml_dir}' --serverName '${var.server_name}' -l '${local.layer}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(yamlencode(var.git_credentials))
      GITOPS_CONFIG   = yamlencode(var.gitops_config)
    }
  }
}*/
resource null_resource setup_gitops {
  depends_on = [null_resource.create_yaml, module.service_account]

  triggers = {
    name = local.name
    namespace = var.namespace
    yaml_dir = local.yaml_dir
    server_name = var.server_name
    layer = local.layer
    type = "base"
    git_credentials = yamlencode(var.git_credentials)
    gitops_config   = yamlencode(var.gitops_config)
    bin_dir = local.bin_dir
  }

  provisioner "local-exec" {
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}' --cascadingDelete=false"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --delete --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }
}
