module "lambda" {
  source            = "genstackio/lambda/aws"
  version           = "0.1.12"
  file              = var.package_file
  s3_bucket         = var.package_s3_bucket
  s3_key            = var.package_s3_key
  name              = var.name
  handler           = var.handler
  timeout           = var.timeout
  memory_size       = var.memory_size
  policy_statements = var.policy_statements
  variables         = merge(
    var.variables,
    {
      AWS_NEXT_PRODUCTION = "1"
      AWS_NEXT_PROJECT_DIR = "/var/task"
    }
  )
}

module "api" {
  source     = "genstackio/apigateway2-api/aws"
  version    = "0.1.3"
  name       = var.name
  lambda_arn = module.lambda.arn
}
