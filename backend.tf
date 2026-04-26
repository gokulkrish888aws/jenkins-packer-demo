terraform {
 backend "s3" {
   bucket = "terraform-state-kt5oc71b"
   key    = "terraform.tfstate"
   region = "us-east-1"
 }
}
