# Terraform AWS ECS Module

A Terraform module for managing [Amazon Elastic Container Service (ECS)](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html) workloads on EC2 container instances. Each building block — cluster, task definition, service and [Amazon ECR](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html) repository — is created independently through its own `*_create` toggle, so a single module can be used to stand up a whole stack or just one piece of it.

## Features

- **Cluster Management**: Creates an ECS cluster with optional Container Insights monitoring.
- **Task Definitions**: Renders a container definition from a local `.template` file and substitutes image, CPU, memory, region, logging, environment variable, secret and port mapping values into it.
- **EFS Volumes**: Optionally attaches an Amazon EFS file system to the task definition as a named volume with a configurable root directory.
- **Service Management**: Creates an EC2 launch type service with a desired task count, deployment percentage limits and optional steady state waiting.
- **ECR Repositories**: Creates a container image repository with AES256 or KMS encryption, mutable or immutable tags and optional scan on push.
- **Independent Toggles**: Every resource is guarded by its own `create` flag, so the module can manage a full stack or a single component.

---

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

---

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

---

## Usage Examples

### Basic Example

Create an ECS cluster on its own:

```hcl
module "ecs_cluster" {
  source = "git::https://github.com/virsas/terraform-aws-ecs.git?ref=v1.1"

  cluster_create   = true
  cluster_name     = "vss-production"
  cluster_insights = "enabled"
}
```

### ECR Repository Example

Create only a container image repository, encrypted with a customer managed KMS key and with immutable tags:

```hcl
module "ecs_ecr" {
  source = "git::https://github.com/virsas/terraform-aws-ecs.git?ref=v1.1"

  ecr_create               = true
  ecr_name                 = "vss/api"
  ecr_encryption_type      = "KMS"
  ecr_kms_key              = "arn:aws:kms:eu-west-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  ecr_image_tag_mutability = "IMMUTABLE"
  ecr_scan_on_push         = true
}
```

### Task Definition Example

Create a task definition from a template file. The module reads `${td_json_path}/${td_file_name}.template` and substitutes the `name`, `image`, `image_version`, `region`, `cpu`, `memory`, `log_driver`, `environment_variables`, `secrets` and `ports` placeholders, so the template has to reference those names.

Given `./json/td/api.template`:

```json
[
  {
    "name": "${name}",
    "image": "${image}:${image_version}",
    "cpu": ${cpu},
    "memory": ${memory},
    "essential": true,
    "portMappings": ${jsonencode(ports)},
    "environment": ${environment_variables},
    "secrets": ${secrets},
    "logConfiguration": {
      "logDriver": "${log_driver}",
      "options": {
        "awslogs-group": "/vss/api",
        "awslogs-region": "${region}"
      }
    }
  }
]
```

```hcl
module "ecs_td" {
  source = "git::https://github.com/virsas/terraform-aws-ecs.git?ref=v1.1"

  td_create         = true
  td_name           = "vss-api"
  td_region         = "eu-west-1"
  td_json_path      = "./json/td"
  td_file_name      = "api"
  td_image          = "123456789012.dkr.ecr.eu-west-1.amazonaws.com/vss/api"
  td_image_version  = "1.4.2"
  td_cpu            = 512
  td_memory         = 1024
  td_log_driver     = "awslogs"
  td_execution_role = "arn:aws:iam::123456789012:role/vss-ecs-execution"
  td_task_role      = "arn:aws:iam::123456789012:role/vss-api-task"

  td_env_vars = jsonencode([
    { name = "APP_ENV", value = "production" },
    { name = "LOG_LEVEL", value = "info" }
  ])

  td_secrets = jsonencode([
    { name = "DB_PASSWORD", valueFrom = "arn:aws:secretsmanager:eu-west-1:123456789012:secret:vss/api/db-6Xy1aB" }
  ])

  td_port_mapping = [
    {
      containerPort = 8080
      hostPort      = 0
    }
  ]
}
```

> [!NOTE]
> `td_env_vars` and `td_secrets` are interpolated into the template as strings, so pass them as pre-rendered JSON (for example with `jsonencode`) rather than as raw Terraform maps or lists.

### Advanced Example (Full Stack with EFS Volume)

Create the cluster, an ECR repository, a task definition with an EFS volume and the service that runs it, all from a single module call:

```hcl
module "ecs" {
  source = "git::https://github.com/virsas/terraform-aws-ecs.git?ref=v1.1"

  cluster_create   = true
  cluster_name     = "vss-production"
  cluster_insights = "enabled"

  ecr_create          = true
  ecr_name            = "vss/worker"
  ecr_encryption_type = "AES256"
  ecr_scan_on_push    = true

  td_create        = true
  td_name          = "vss-worker"
  td_region        = "eu-west-1"
  td_file_name     = "worker"
  td_image         = "123456789012.dkr.ecr.eu-west-1.amazonaws.com/vss/worker"
  td_image_version = "2.0.0"
  td_cpu           = 1024
  td_memory        = 2048

  td_volume  = "shared-data"
  td_efs_id  = "fs-0123456789abcdef0"
  td_efs_dir = "/worker"

  service_create  = true
  service_name    = "vss-worker"
  service_count   = 3
  service_cluster = "vss-production"
  service_td      = "vss-worker"
  service_maxperc = 200
  service_minperc = 100
  service_wait    = true
}
```

---

## Resources

| Name | Type |
|------|------|
| [aws_ecs_cluster.vss](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_task_definition.vss](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_ecs_service.vss](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecr_repository.vss](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_create"></a> [cluster\_create](#input\_cluster\_create) | Whether to create the ECS cluster. | `bool` | `false` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the ECS cluster, required when `cluster_create` is `true`. | `string` | `""` | no |
| <a name="input_cluster_insights"></a> [cluster\_insights](#input\_cluster\_insights) | Whether to enable Amazon ECS Container Insights for the cluster. Allowed values are `enabled` and `disabled`. | `string` | `"disabled"` | no |
| <a name="input_td_create"></a> [td\_create](#input\_td\_create) | Whether to create the ECS task definition. | `bool` | `false` | no |
| <a name="input_td_name"></a> [td\_name](#input\_td\_name) | The name of the task definition family, required when `td_create` is `true`. | `string` | `""` | no |
| <a name="input_td_region"></a> [td\_region](#input\_td\_region) | The AWS region substituted into the `region` placeholder of the template file, required when `td_create` is `true`. | `string` | `""` | no |
| <a name="input_td_execution_role"></a> [td\_execution\_role](#input\_td\_execution\_role) | ARN of the task execution role assumed by the ECS container agent and the Docker daemon. Defaults to `null`, which falls back to the EC2 instance role. | `string` | `null` | no |
| <a name="input_td_task_role"></a> [td\_task\_role](#input\_td\_task\_role) | ARN of the IAM role that allows the task to call other AWS services. Defaults to `null`, which falls back to the EC2 instance role. | `string` | `null` | no |
| <a name="input_td_json_path"></a> [td\_json\_path](#input\_td\_json\_path) | Path to the directory containing the task definition template file. | `string` | `"./json/td"` | no |
| <a name="input_td_file_name"></a> [td\_file\_name](#input\_td\_file\_name) | Name of the task definition template file without the `.template` extension, required when `td_create` is `true`. | `string` | `""` | no |
| <a name="input_td_image"></a> [td\_image](#input\_td\_image) | Docker image substituted into the `image` placeholder of the template file, required when `td_create` is `true`. | `string` | `""` | no |
| <a name="input_td_image_version"></a> [td\_image\_version](#input\_td\_image\_version) | Docker image tag substituted into the `image_version` placeholder of the template file. | `string` | `"latest"` | no |
| <a name="input_td_cpu"></a> [td\_cpu](#input\_td\_cpu) | Number of CPU units to reserve for the container, substituted into the `cpu` placeholder of the template file. | `number` | `256` | no |
| <a name="input_td_memory"></a> [td\_memory](#input\_td\_memory) | Amount of memory in MiB to reserve for the container, substituted into the `memory` placeholder of the template file. | `number` | `512` | no |
| <a name="input_td_log_driver"></a> [td\_log\_driver](#input\_td\_log\_driver) | Log driver substituted into the `log_driver` placeholder of the template file, for example `awslogs`, `json-file`, `awsfirelens` or `fluentd`. | `string` | `"awslogs"` | no |
| <a name="input_td_env_vars"></a> [td\_env\_vars](#input\_td\_env\_vars) | Environment variables substituted into the `environment_variables` placeholder of the template file, passed as pre-rendered JSON because the value is interpolated as a string. | `any` | `null` | no |
| <a name="input_td_secrets"></a> [td\_secrets](#input\_td\_secrets) | Secrets substituted into the `secrets` placeholder of the template file, passed as pre-rendered JSON because the value is interpolated as a string. | `any` | `null` | no |
| <a name="input_td_volume"></a> [td\_volume](#input\_td\_volume) | Name of the volume to attach to the task definition, referenced as `sourceVolume` in the template file. Leaving it `null` creates no volume. | `string` | `null` | no |
| <a name="input_td_efs_id"></a> [td\_efs\_id](#input\_td\_efs\_id) | ID of the EFS file system to mount into the volume defined by `td_volume`. | `string` | `null` | no |
| <a name="input_td_efs_dir"></a> [td\_efs\_dir](#input\_td\_efs\_dir) | Directory within the EFS file system to mount as the root directory of the volume. | `string` | `"/"` | no |
| <a name="input_td_port_mapping"></a> [td\_port\_mapping](#input\_td\_port\_mapping) | Port mappings substituted into the `ports` placeholder of the template file. Use a `hostPort` of `0` for dynamic port mapping. | <pre>list(object({<br>  containerPort = number<br>  hostPort      = number<br>}))</pre> | `[]` | no |
| <a name="input_service_create"></a> [service\_create](#input\_service\_create) | Whether to create the ECS service. | `bool` | `false` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | The name of the ECS service, required when `service_create` is `true`. | `string` | `""` | no |
| <a name="input_service_count"></a> [service\_count](#input\_service\_count) | The desired number of tasks for the service. | `number` | `1` | no |
| <a name="input_service_cluster"></a> [service\_cluster](#input\_service\_cluster) | Name or ARN of the ECS cluster to create the service in, required when `service_create` is `true`. | `string` | `""` | no |
| <a name="input_service_td"></a> [service\_td](#input\_service\_td) | Family, family and revision, or ARN of the task definition to run in the service, required when `service_create` is `true`. | `string` | `""` | no |
| <a name="input_service_maxperc"></a> [service\_maxperc](#input\_service\_maxperc) | Upper limit, as a percentage of the desired count, of tasks that may run during a deployment. Must be between `100` and `200`. | `number` | `100` | no |
| <a name="input_service_minperc"></a> [service\_minperc](#input\_service\_minperc) | Lower limit, as a percentage of the desired count, of tasks that must stay running and healthy during a deployment. Must be between `0` and `100`. | `number` | `50` | no |
| <a name="input_service_wait"></a> [service\_wait](#input\_service\_wait) | Whether Terraform waits for the service to reach a steady state before completing. | `bool` | `true` | no |
| <a name="input_ecr_create"></a> [ecr\_create](#input\_ecr\_create) | Whether to create the ECR repository. | `bool` | `false` | no |
| <a name="input_ecr_name"></a> [ecr\_name](#input\_ecr\_name) | The name of the ECR repository, required when `ecr_create` is `true`. | `string` | `""` | no |
| <a name="input_ecr_encryption_type"></a> [ecr\_encryption\_type](#input\_ecr\_encryption\_type) | Encryption type for the repository. Allowed values are `AES256` and `KMS`. | `string` | `"AES256"` | no |
| <a name="input_ecr_kms_key"></a> [ecr\_kms\_key](#input\_ecr\_kms\_key) | ARN of the KMS key used when `ecr_encryption_type` is `KMS`. Leave it `null` when using `AES256`. | `string` | `null` | no |
| <a name="input_ecr_image_tag_mutability"></a> [ecr\_image\_tag\_mutability](#input\_ecr\_image\_tag\_mutability) | Tag mutability setting for the repository. Allowed values are `MUTABLE` and `IMMUTABLE`. | `string` | `"MUTABLE"` | no |
| <a name="input_ecr_scan_on_push"></a> [ecr\_scan\_on\_push](#input\_ecr\_scan\_on\_push) | Whether images are scanned for vulnerabilities after being pushed to the repository. | `bool` | `false` | no |

---

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | The ID of the ECS cluster, or `null` when the cluster is not created. |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | The ARN of the ECS cluster, or `null` when the cluster is not created. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the ECS cluster, or `null` when the cluster is not created. |
| <a name="output_td_arn"></a> [td\_arn](#output\_td\_arn) | The full ARN of the task definition including its revision, or `null` when the task definition is not created. |
| <a name="output_td_arn_without_revision"></a> [td\_arn\_without\_revision](#output\_td\_arn\_without\_revision) | The ARN of the task definition family without the revision suffix, or `null` when the task definition is not created. |
| <a name="output_td_revision"></a> [td\_revision](#output\_td\_revision) | The revision number of the task definition, or `null` when the task definition is not created. |
| <a name="output_service_id"></a> [service\_id](#output\_service\_id) | The ID of the ECS service, or `null` when the service is not created. |
| <a name="output_ecr_arn"></a> [ecr\_arn](#output\_ecr\_arn) | The ARN of the ECR repository, or `null` when the repository is not created. |
| <a name="output_ecr_registry_id"></a> [ecr\_registry\_id](#output\_ecr\_registry\_id) | The registry ID of the ECR repository, or `null` when the repository is not created. |
| <a name="output_ecr_repository_url"></a> [ecr\_repository\_url](#output\_ecr\_repository\_url) | The URL of the ECR repository, or `null` when the repository is not created. |

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
