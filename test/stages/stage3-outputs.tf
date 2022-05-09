
resource null_resource write_outputs {
  provisioner "local-exec" {
    command = "echo \"$${OUTPUT}\" > gitops-output.json"

    environment = {
      OUTPUT = jsonencode({
        name        = module.gitops_console_link.name
        branch      = module.gitops_console_link.branch
        namespace   = module.gitops_console_link.namespace
        server_name = module.gitops_console_link.server_name
        layer       = module.gitops_console_link.layer
        layer_dir   = module.gitops_console_link.layer == "infrastructure" ? "1-infrastructure" : (module.gitops_console_link.layer == "services" ? "2-services" : "3-applications")
        type        = module.gitops_console_link.type
      })
    }
  }
}
