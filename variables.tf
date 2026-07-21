# Cluster

variable "cluster_create" {
  description = "Whether to create the ECS cluster. Defaults to false."
  type = bool
  default = false
}

variable "cluster_name" {
  description = "The name of the ECS cluster. This should be a unique identifier for your cluster."
  type = string
  default = ""
  validation {
    condition = var.cluster_create == false || (var.cluster_create == true && length(var.cluster_name) > 0)
    error_message = "The 'cluster_name' variable is required when 'cluster_create' is set to true."
  }
}

variable "cluster_insights" {
  description = "Indicates whether to enable Amazon ECS Container Insights for the cluster. Valid values are 'enabled' or 'disabled'. Defaults to 'disabled'."
  type = string
  default = "disabled"
  validation {
    condition     = contains(["enabled", "disabled"], var.cluster_insights)
    error_message = "Invalid value for 'cluster_insights'. Must be one of: 'enabled', 'disabled'."
  }
}

# TD

variable "td_create" {
  description = "Whether to create the ECS Task Definition. Defaults to false."
  type        = bool
  default     = false
}

variable "td_name" {
  description = "The name of the Task Definition family. This should be a unique identifier for your task definition."
  type        = string
  default     = ""
  validation {
    condition = var.td_create == false || (var.td_create == true && length(var.td_name) > 0)
    error_message = "The 'td_name' variable is required when 'td_create' is set to true."
  }
}

variable "td_region" {
  description           = "The AWS region to deploy resources in. Defaults to 'eu-west-1'."
  type                  = string
  default     = ""
  validation {
    condition = var.td_create == false || (var.td_create == true && length(var.td_region) > 0)
    error_message = "The 'td_region' variable is required when 'td_create' is set to true."
  }
}

variable "td_execution_role" {
  description = "The ARN of the task execution role that the Amazon ECS container agent and the Docker daemon can assume. This role allows your containers to access AWS resources. Defaults to null, which uses the EC2 instance role."
  type        = string
  default     = null
}

variable "td_task_role" {
  description = "The ARN of the IAM role that allows your Amazon ECS container task to make calls to other AWS services. Defaults to null, which uses the EC2 instance role."
  type        = string
  default     = null
}

variable "td_json_path" {
  description = "The path to the directory containing the task definition template file. The template file should be named TD_NAME.template'. Defaults to './json/td'."
  type        = string
  default     = "./json/td"
}

variable "td_file_name" {
  description = "The name of the task definition template file (without the .template extension). This file should contain the JSON configuration for the task definition."
  type        = string
  default     = ""
  validation {
    condition = var.td_create == false || (var.td_create == true && length(var.td_file_name) > 0)
    error_message = "The 'td_file_name' variable is required when 'td_create' is set to true."
  }
}

variable "td_image" {
  description = "The name of the Docker image to use for the container in the task definition. This value will be substituted into the 'image' placeholder in the template file."
  type        = string
  default     = ""
  validation {
    condition = var.td_create == false || (var.td_create == true && length(var.td_image) > 0)
    error_message = "The 'td_image' variable is required when 'td_create' is set to true."
  }
}

variable "td_image_version" {
  description = "The version of the Docker image to use for the container in the task definition. This value will be substituted into the 'image_version' placeholder in the template file. Defaults to 'latest'."
  type        = string
  default     = "latest"
}

variable "td_cpu" {
  description = "The number of CPU units to reserve for the container. This value will be substituted into the 'cpu' placeholder in the template file. Defaults to 256."
  type        = number
  default     = 256
}
variable "td_memory" {
  description = "The amount of memory (in MiB) to reserve for the container. This value will be substituted into the 'memory' placeholder in the template file. Defaults to 512."
  type        = number
  default     = 512
}
variable "td_log_driver" {
  description = "The log driver to use for the container. This value will be substituted into the 'log_driver' placeholder in the template file. Defaults to 'awslogs'."
  type        = string
  default     = "awslogs"
}

variable "td_env_vars" {
  description = <<EOD
Environment variables to inject into the task definition template file. This should be a map or a string representation of a map.
If you use external data from tools like 1Password, you can use locals to construct this map and then inject it into the template file.
This value will be substituted into the 'environment_variables' placeholder in the template file.
EOD
  type        = any
  default     = null
}

variable "td_secrets" {
  description = <<EOD
Secrets to inject into the task definition template file. This should be a map or a string representation of a map.
If you use external data from tools like 1Password, you can use locals to construct this map and then inject it into the template file.
This value will be substituted into the 'secrets' placeholder in the template file.
EOD
  type        = any
  default     = null
}

variable "td_volume" {
  description = "The name of the EFS volume to mount in the task definition. This is the name that will be referenced as 'sourceVolume' in the template file."
  type        = string
  default     = null
}

variable "td_efs_id" {
  description = "The ID of the EFS file system to mount."
  type        = string
  default     = null
}

variable "td_efs_dir" {
  description = "The directory within the Amazon EFS file system to mount as the root directory inside the container. Defaults to '/'."
  type        = string
  default     = "/"
}

variable "td_port_mapping" {
  description = "The port mapping configuration for the container. This should be a list of maps, each containing 'containerPort' and 'hostPort'."
  type        = list(object({
    containerPort = number
    hostPort      = number
  }))
  default     = []
}

# Service

variable "service_create" {
  description = "Whether to create the ECS service. Defaults to false."
  type = bool
  default = false
}

variable "service_name" {
  description = "The name of the ECS service. This should be a unique identifier for your service."
  type = string
  default = ""
  validation {
    condition = var.service_create == false || (var.service_create == true && length(var.service_name) > 0)
    error_message = "The 'service_name' variable is required when 'service_create' is set to true."
  }
}

variable "service_count" {
  description = "The desired number of tasks for the service. Defaults to 1."
  type = number
  default = 1
}

variable "service_cluster" {
  description = "The ID of the ECS cluster to create the service in."
  type = string
  default = ""
  validation {
    condition = var.service_create == false || (var.service_create == true && length(var.service_cluster) > 0)
    error_message = "The 'service_cluster' variable is required when 'service_create' is set to true."
  }
}

variable "service_td" {
  description = "The ARN of the task definition to use for tasks in the service."
  type = string
  default = ""
  validation {
    condition = var.service_create == false || (var.service_create == true && length(var.service_td) > 0)
    error_message = "The 'service_td' variable is required when 'service_create' is set to true."
  }
}

variable "service_maxperc" {
  description = "The upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment. Defaults to 100."
  type = number
  default = 100
  validation {
    condition     = var.service_maxperc >= 100 && var.service_maxperc <= 200
    error_message = "The 'service_maxperc' variable must be a number between 100 and 200."
  }
}

variable "service_minperc" {
  description = "The lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment. Defaults to 50."
  type = number
  default = 50
  validation {
    condition     = var.service_minperc >= 0 && var.service_minperc <= 100
    error_message = "The 'service_minperc' variable must be a number between 0 and 100."
  }
}

variable "service_wait" {
  description = "Indicates whether to wait for the service to reach a steady state. Defaults to true."
  type = bool
  default = true
}

# ECR

variable "ecr_create" {
  description = "Whether to create the ECR repository. Defaults to false."
  type = bool
  default = false
}

variable "ecr_name" {
  description = "The name of the ECR repository. This should be a unique identifier for your repository."
  type = string
  default = ""
  validation {
    condition = var.ecr_create == false || (var.ecr_create == true && length(var.ecr_name) > 0)
    error_message = "The 'ecr_name' variable is required when 'ecr_create' is set to true."
  }
}

variable "ecr_encryption_type" {
  description = "The encryption type to use for the repository. Valid values are 'AES256' or 'KMS'. Defaults to 'AES256'."
  type = string
  default = "AES256"
  validation {
    condition     = contains(["AES256", "KMS"], var.ecr_encryption_type)
    error_message = "Invalid value for 'ecr_encryption_type'. Must be one of: 'AES256', 'KMS'."
  }
}

variable "ecr_kms_key" {
  description = "The ARN of the KMS key to use when encrypting the repository with 'KMS' encryption type. If 'ecr_encryption_type' is 'AES256', this value is ignored."
  type = string
  default = null
}

variable "ecr_image_tag_mutability" {
  description = "The tag mutability setting for the repository. Valid values are 'MUTABLE' or 'IMMUTABLE'. Defaults to 'MUTABLE'."
  type = string
  default = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.ecr_image_tag_mutability)
    error_message = "Invalid value for 'ecr_image_tag_mutability'. Must be one of: 'MUTABLE', 'IMMUTABLE'."
  }
}

variable "ecr_scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository. Defaults to false."
  type = bool
  default = false
}
