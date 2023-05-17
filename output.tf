output "region" {
  value = var.aws_region
}

output "vpc_id" {
  value = module.vpc_module.vpc_id
}

output "private_subnets_id" {
  value = module.vpc_module.private_subnets_id
}

output "public_subnets_id" {
  value = module.vpc_module.public_subnets_id
}

output "vpc_cidr" {
  value = module.vpc_module.vpc_cidr
}
