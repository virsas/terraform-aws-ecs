resource "aws_ecs_cluster" "vss" {
  count  = var.cluster_create ? 1 : 0

  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = var.cluster_insights
  }
}

resource "aws_ecs_task_definition" "vss" {
  count  = var.td_create ? 1 : 0

  family                    = var.td_name

  execution_role_arn        = var.td_execution_role
  task_role_arn             = var.td_task_role

  network_mode              = "bridge"

  container_definitions     = templatefile("${var.td_json_path}/${var.td_file_name}.template", {
    name = "${var.td_name}"
    image = "${var.td_image}"
    image_version = "${var.td_image_version}"
    region = "${var.td_region}"
    cpu = "${var.td_cpu}"
    memory = "${var.td_memory}"
    log_driver = "${var.td_log_driver}"
    environment_variables = "${var.td_env_vars}"
    secrets = "${var.td_secrets}"
    ports = var.td_port_mapping
  })

  dynamic "volume" {
    for_each = var.td_volume != null ? [1] : []

    content {
      name = var.td_volume

      dynamic "efs_volume_configuration" {
        for_each = var.td_efs_id != null && var.td_efs_dir != null ? [1] : []
        content {
          file_system_id     = var.td_efs_id
          root_directory     = var.td_efs_dir
        }
      }
    }
  }
}

resource "aws_ecs_service" "vss" {
  count  = var.service_create ? 1 : 0

  name            = var.service_name
  desired_count   = var.service_count

  cluster         = var.service_cluster
  task_definition = var.service_td

  launch_type     = "EC2"

  deployment_maximum_percent = var.service_maxperc
  deployment_minimum_healthy_percent = var.service_minperc

  wait_for_steady_state = var.service_wait
}

resource "aws_ecr_repository" "vss" {
  count  = var.ecr_create ? 1 : 0

  name = var.ecr_name

  encryption_configuration {
    encryption_type = var.ecr_encryption_type
    kms_key         = var.ecr_kms_key
  }

  image_tag_mutability = var.ecr_image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }
}