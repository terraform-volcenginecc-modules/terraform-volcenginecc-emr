# complete

## 1. Overview

Spark/Hive data lake and batch workers: 1 Master, 2 Core nodes, and one independent TASK group with 2 nodes by default. Private TOS stores Hive managed/external warehouses and Spark event/history logs. Bootstrap references a real caller-uploaded script.

## 2. Usage

The intended source is `terraform-volcenginecc-modules/emr/volcenginecc`, pending publication. For draft execution, change source to `../..` in a local checkout; static validation changes only temporary copies. Fill required inputs in an ignored `terraform.tfvars`. Supply credentials through `VOLCENGINE_ACCESS_KEY` / `VOLCENGINE_SECRET_KEY` or a supported profile. Exclude `dev_overrides` and use the official Provider.

```shell
terraform init -backend=false
terraform validate
terraform plan
terraform apply
terraform plan -detailed-exitcode
terraform destroy
```

For OpenTofu, substitute `tofu`, using a separate directory and State. These commands create billable resources. Complete passed the Terraform 1.5.7 cloud lifecycle with official Provider 0.0.73; OpenTofu cloud execution remains unverified.

## 3. Examples

Compared with `examples/basic`, adds HIVE, an independent TASK group, Bootstrap, TOS settings, and tags. Does not execute Spark/Hive business jobs.

## 4. Requirements

| Requirement | Version / condition |
|---|---|
| Terraform | `1.5.7` |
| OpenTofu | `1.11.8` |
| Existing dependencies | Matching network, ECS IAM Role, SSH key pair, private TOS bucket, actual uploaded Bootstrap script |
| Cloud prerequisites | Release supporting SPARK3/HIVE and TOS connector; matching specifications and quotas |

Scripts may use a separate bucket. The caller manages object permissions, access, retention, and data cleanup.

## 5. Providers

| Name | Source | Version |
|---|---|---|
| volcenginecc | `volcengine/volcenginecc` | `= 0.0.73` |

## 6. Resources

| Managed through module | Count |
|---|---|
| `volcenginecc_emr_cluster` | 1, including initial Master/Core |
| `volcenginecc_emr_node_group` | 1 independent TASK group keyed `batch` |

Creates no external dependencies or TOS objects.

## 7. Inputs

| Name | Type | Default | Required | Description |
|---|---|---|---|---|
| region | string | — | yes | Region |
| cluster_name | string | — | yes | Cluster name |
| release_version | string | — | yes | Release supporting SPARK3/HIVE |
| network | object | — | yes | vpc_id, subnet_id, security_group_id, zone_id |
| ecs_iam_role | string | — | yes | Role authorized for data/log/script paths |
| ecs_key_pair_name | string | — | yes | Existing SSH key pair |
| master_instance_type | string | — | yes | Master ECS type |
| worker_instance_type | string | — | yes | Core/TASK ECS type |
| disk_type | string | — | yes | Supported EMR disk type |
| tos_bucket_name | string | — | yes | Existing private bucket name without tos:// |
| bootstrap_script_path | string | — | yes | Actual uploaded tos://bucket/key script |
| task_node_count | number | `2` | no | Manual desired TASK capacity |
| tags | map(string) | `{ scenario = "spark-hive-data-lake" }` | no | Cluster tags |

## 8. Outputs

| Name | Description |
|---|---|
| cluster_id | Cluster ID |
| task_node_group_ids | TASK key to group ID |
| applications | Installed components and actual versions |
| data_lake_paths | Caller-owned managed/external warehouse and Spark event log paths |

## 9. Notes

On 2026-11-04, complete passed Plan/Apply/second plan No changes/standard Destroy on Terraform 1.5.7 and official Provider 0.0.73. All 5 nodes and 16 disks were independently confirmed absent. Bootstrap on all 5 nodes, Spark/Hive TOS queries (10 rows, sum 45), TOS event logs, and History Server reads passed. TASK updates/removal remain unverified. Spark event logs are not all EMR system logs; no TLS collection is configured.

Provider 0.0.60 and 0.0.73 expose no EMR autoscaling policy. Change `task_node_count` manually, then verify a second plan with No changes. Do not let another system concurrently manage capacity. Removing `batch` should remove only that TASK group; real State validation is needed. Inspect replacement plans before changing initial groups, release, or Bootstrap.

Do not put credentials in scripts, arguments, or application values. Destroy removes module-owned cluster/TASK groups. Independently confirm EMR, ECS, and disk absence. Preserve caller dependencies and TOS data.
