output "lambda_arn" {
  value = module.lambda.arn
}
output "lambda_qualified_arn" {
  value = module.lambda.qualified_arn
}
output "lambda_name" {
  value = module.lambda.name
}
output "lambda_role_name" {
  value = module.lambda.role_name
}
output "lambda_invoke_arn" {
  value = module.lambda.invoke_arn
}
output "endpoint" {
  value = module.api.endpoint
}
output "dns" {
  value = module.api.dns
}