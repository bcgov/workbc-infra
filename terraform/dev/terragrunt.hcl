terraform {
  source = "./"
}

include {
  path = find_in_parent_folders()
}

/*
locals {
  project = get_env("LICENSE_PLATE")
}*/

generate "dev_tfvars" {
  path              = "dev.auto.tfvars"
  if_exists         = "overwrite"
  disable_signature = true
  contents          = <<-EOF
    cloudfront = true
  EOF
}
