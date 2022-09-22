locals {
  layer = "services"
  yaml_dir = "${path.cwd}/.tmp/console-link-job"
  name = "console-link-job"
  application_branch = "main"
  type = "base"
}

resource gitops_service_account sa {
  name = "console-link-job"
  namespace = var.namespace
  server_name = var.server_name
  config = var.gitops_config
  credentials = var.git_credentials

  cluster_scope = true
  rules {
    api_groups = [""]
     resources = ["configmaps"]
     verbs = ["*"]
  }
  rules {
    api_groups = ["apps"]
    resources = ["daemonsets"]
    verbs = ["list", "get"]
  }
  rules {
    api_groups = ["route.openshift.io"]
    resources = ["routes"]
    verbs = ["list", "get"]
  }
  rules {
    api_groups = ["console.openshift.io"]
    resources = ["consolelinks"]
    verbs = ["*"]
  }
}

resource null_resource create_yaml {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.yaml_dir}' '${gitops_service_account.sa.name}'"
  }
}

resource gitops_module module {
  depends_on = [null_resource.create_yaml, gitops_service_account.sa]

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
