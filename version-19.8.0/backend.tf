terraform {
  backend "local" {}
}

# # Configure S3 Backend
# terraform {
#   backend "s3" {
#     bucket         = "onyi-terraform-state"
#     key            = "global/s3-eks-official/terraform.tfstate"
#     region         = "us-east-2"
#     encrypt        = true
#   }
# }