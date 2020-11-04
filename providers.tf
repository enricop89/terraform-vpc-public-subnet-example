provider "aws" {
  profile = var.profile
  region  = var.region-main
  alias   = "region-main"
}