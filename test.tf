terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}
 # required_version = ">= 0.14.9"

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}



resource "aws_s3_bucket" "unrestricted" {
  #zpc-skip-policy: ZS-AWS-00034:testing
  bucket = "examplebuckettftest"
  acl    = "private"
  versioning {
    enabled = true
  }
  logging {
    target_bucket = "pavantestbucket"
    target_prefix = "log/"
    }
}
}
}
