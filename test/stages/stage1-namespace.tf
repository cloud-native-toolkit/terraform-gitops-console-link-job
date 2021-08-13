module "gitops_namespace" {
  source = "github.com/cloud-native-toolkit/terraform-gitops-namespace.git"

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  name = var.namespace
  argocd_namespace = "openshift-gitops"
  argocd_service_account      = "argocd-cluster-argocd-application-controller"
}
