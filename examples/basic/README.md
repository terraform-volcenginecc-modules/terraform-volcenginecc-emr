# BASIC EMR Example

## 1. Overview

This example creates a private Spark/Hadoop cluster with 1 Master and 2 Core nodes and installs HDFS, YARN, and SPARK3. The caller provides a Subnet and security group in the same VPC and zone, an ECS IAM Role, an SSH key pair, and supported EMR release, ECS, and disk specifications. Unlike complete, it creates no TASK group and configures no Hive or TOS data lake.

## 2. Usage

Configure inputs and run these commands from `examples/basic`:

```shell
terraform init
terraform plan
terraform apply
terraform plan
terraform destroy
```

Use the first Plan to review the creation scope. The Plan after Apply should show no changes. Before Destroy, confirm that the current State contains only the EMR cluster managed by this example. Existing network, IAM Role, and SSH key-pair resources remain.

## 3. Requirements

| Name | Version |
|---|---|
| Terraform | `>= 1.5.7, < 2.0.0` |
| `volcengine/volcenginecc` | `= 0.0.73` |

## 4. Providers

| Name | Source |
|---|---|
| `volcenginecc` | `volcengine/volcenginecc` |

## 5. Resources

| Name | Description |
|---|---|
| `module.emr` | Uses `terraform-volcenginecc-modules/emr/volcenginecc` to create the EMR cluster and initial Master/Core groups. |

This example declares no Resource or Data Source directly.

## 6. Inputs

| Name | Description |
|---|---|
| `region` | Deployment region, also used to configure the `volcenginecc` Provider. |
| `cluster_name` | EMR cluster name. |
| `release_version` | EMR release available in the target region and supporting HDFS, YARN, and SPARK3. |
| `network` | Existing `vpc_id`, `subnet_id`, `security_group_id`, and `zone_id`; the Subnet and zone must match. |
| `ecs_iam_role` | Existing ECS IAM Role with permissions required by EMR. |
| `ecs_key_pair_name` | Existing ECS SSH key-pair name. |
| `instance_type` | EMR-supported ECS specification used by both Master and Core nodes in the target zone. |
| `disk_type` | EMR disk type supported in the target zone. |

## 7. Outputs

| Name | Description |
|---|---|
| `cluster_id` | ID of the created EMR cluster. |
| `applications` | Installed application and actual version information returned by the Provider. |

## 8. Example

This directory contains the basic example for deploying a minimal Spark/Hadoop cluster first. Use complete when HIVE, an independent TASK group, TOS Hive warehouses, or Spark event logs are required.

## 9. Notes

- Supply Provider credentials through environment variables, shared configuration, or the runtime platform's credential manager. Do not store them in source or variable files.
- Run `terraform plan` again after Apply. Idempotence requires the final Plan to show no changes.
- The caller manages security-group rules and outbound connectivity.
- Review the Plan before changing the release, network, or initial node groups to identify cluster replacement.
- `terraform destroy` removes the module-managed EMR cluster while preserving caller-owned network, IAM Role, and SSH key pair.
