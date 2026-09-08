# Absichtlich fehlkonfiguriertes Beispiel für den IaC-Scan (Checkov).
# Wird in der Pipeline nur statisch analysiert, nie mit `terraform apply` ausgeführt -
# es sind keine echten Cloud-Credentials im Repo/Workflow hinterlegt.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "demo_bucket" {
  bucket = "devsecops-lab-demo-bucket"
  acl    = "public-read" # sollte nicht public-read sein, siehe CKV_AWS_20

  # Absichtlich keine server_side_encryption_configuration -> CKV_AWS_21
  # Absichtlich kein versioning-Block -> CKV2_AWS_6
}
