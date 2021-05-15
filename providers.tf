provider "aws" {
}
provider "aws" {
  alias = "acm"
}
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}