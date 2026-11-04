# basic

## 1. Overview

Spark/Hadoop offline ETL: 1 Master, 2 Core nodes, HDFS/YARN/SPARK3, pay-as-you-go billing, and private nodes. Uses existing network, IAM Role, and SSH key pair.

## 2. Usage

The intended source is `terraform-volcenginecc-modules/emr/volcenginecc`, pending publication. Run the draft by changing the module source in a local checkout to `../..`; static validation changes only temporary copies. Set all required inputs in an ignored `terraform.tfvars`. Provide credentials using `VOLCENGINE_ACCESS_KEY` / `VOLCENGINE_SECRET_KEY` or a supported profile. Exclude `dev_overrides` to use the official Provider.

```shell
terraform init -backend=false
terraform validate
terraform plan
terraform apply
terraform plan -detailed-exitcode
terraform destroy
```

For OpenTofu, substitute `tofu`, using a separate directory and State. These commands create billable resources; OpenTofu cloud execution is unverified.

## 3. Examples

This is the basic scenario. `examples/complete` adds TASK workers, Bootstrap, Hive warehouses, and Spark event logs.

## 4. Requirements

| Requirement | Version / condition |
|---|---|
| Terraform | `1.5.7` |
| OpenTofu | `1.11.8` |
| Existing dependencies | Same-VPC network, matching Subnet/zone/security group, ECS IAM Role, SSH key pair |
| Cloud prerequisites | Enabled EMR; supported release, components, instance/disk specifications; sufficient quotas |

## 5. Providers

| Name | Source | Version |
|---|---|---|
| volcenginecc | `volcengine/volcenginecc` | `= 0.0.73` |

## 6. Resources

| Managed through module | Count |
|---|---|
| `volcenginecc_emr_cluster` | 1, including initial Master/Core |

Creates no independent TASK groups or external dependencies.

## 7. Inputs

| Name | Type | Default | Required | Description |
|---|---|---|---|---|
| region | string | — | yes | Region |
| cluster_name | string | — | yes | Cluster name |
| release_version | string | — | yes | Available EMR release |
| network | object | — | yes | vpc_id, subnet_id, security_group_id, zone_id |
| ecs_iam_role | string | — | yes | Authorized existing ECS Role |
| ecs_key_pair_name | string | — | yes | Existing SSH key pair |
| instance_type | string | — | yes | EMR-supported ECS type |
| disk_type | string | — | yes | Supported EMR disk type |

## 8. Outputs

| Name | Description |
|---|---|
| cluster_id | EMR cluster ID |
| applications | Installed components and actual versions |

## 9. Notes

On 2026-11-04, Terraform 1.5.7 and official Provider 0.0.73 passed creation and core-service startup. After fixing empty `application_extras` read-back differences, the second plan returned No changes (exit 0). Standard destroy succeeded; all 3 ECS nodes and 12 disks were independently confirmed absent. Business jobs and other deployment/security modes remain unverified.

The caller manages security-group rules and outbound connectivity. Keep credentials out of the repository. A second plan must return 0; after destroy, independently query EMR, ECS, and disks for absence. Caller dependencies remain.
