provider "kubernetes" {
  cluster_ca_certificate = base64decode(var.kubernetes_cluster_cert_data)
  host                   = var.kubernetes_cluster_endpoint
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws-iam-authenticator"
    args        = ["token", "-i", "${var.kubernetes_cluster_name}"]
  }
}

provider "helm" {
  kubernetes = {
    cluster_ca_certificate = base64decode(var.kubernetes_cluster_cert_data)
    host                   = var.kubernetes_cluster_endpoint
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws-iam-authenticator"
      args        = ["token", "-i", "${var.kubernetes_cluster_name}"]
    }
  }
}

resource "kubernetes_namespace_v1" "example" {
  metadata {
    name = "argo"
  }
}

resource "helm_release" "argocd" {
  name       = "msur"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  namespace  = "argo"
  depends_on = [
    kubernetes_namespace_v1.example
  ]

  timeout          = 3600    # Increase to 1 hour
  wait             = true   # Wait for all pods to be "Ready" before finishing
  cleanup_on_fail  = true   # Automatically delete failed attempts
  atomic           = true   # Roll back if it fails again
}

