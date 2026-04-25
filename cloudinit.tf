data "cloudinit_config" "cloudinit-jenkins" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content      = templatefile("scripts/jenkins-init.sh", {
      DEVICE            = var.INSTANCE_DEVICE_NAME
      TERRAFORM_VERSION = var.TERRAFORM_VERSION
      PACKER_VERSION    = var.PACKER_VERSION
    })
  }
}

