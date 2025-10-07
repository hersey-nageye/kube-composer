# Remote backend configuration for Terraform state management.
terraform {
  backend "s3" {
    bucket            = "eks-project-tfstate"
    key               = "eks/dev/terraform.tfstate"
    region            = "eu-west-2"
    dynamodb_endpoint = "eks-projects-locks"
    encrypt           = true
  }

}
