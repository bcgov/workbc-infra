/*resource "helm_release" "secrets_store_csi_driver" {
  name       = "csi-secrets-store"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  version    = "1.4.3"  # Use latest

  set = [{
    name  = "syncSecret.enabled"
    value = "true"
  }]
}

resource "helm_release" "secrets_store_csi_aws_provider" {
  name       = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  depends_on = [helm_release.secrets_store_csi_driver]
}
*/
