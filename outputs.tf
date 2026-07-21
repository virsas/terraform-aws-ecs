output "cluster_id" {
  value = try(aws_ecs_cluster.vss[0].id, null)
}
output "cluster_arn" {
  value = try(aws_ecs_cluster.vss[0].arn, null)
}
output "cluster_name" {
  value = try(aws_ecs_cluster.vss[0].name, null)
}
output "td_arn" {
  value = try(aws_ecs_task_definition.vss[0].arn, null)
}
output "td_arn_without_revision" {
  value = try(aws_ecs_task_definition.vss[0].arn_without_revision, null)
}
output "td_revision" {
  value = try(aws_ecs_task_definition.vss[0].revision, null)
}
output "service_id" {
  value = try(aws_ecs_service.vss[0].id, null)
}
output "ecr_arn" {
  value = try(aws_ecr_repository.vss[0].arn, null)
}
output "ecr_registry_id" {
  value = try(aws_ecr_repository.vss[0].registry_id, null)
}
output "ecr_repository_url" {
  value = try(aws_ecr_repository.vss[0].repository_url, null)
}
