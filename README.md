# terraform-volcenginecc-emr

## 1. Overview

EMR for Spark/Hadoop/Hive offline ETL, data lake computing, and batch processing. Manages one pay-as-you-go cluster, initial Master/Core groups, and optional independent TASK groups. Release, components, disks, Bootstrap, application settings, and tags are configurable. The caller owns network, IAM, SSH keys, TOS objects, and business jobs.

Status: **draft; Registry publication pending**. On 2026-11-04, basic passed creation, core-service startup, second plan No changes, and standard destroy, with 3 nodes and 12 disks independently confirmed absent, on Terraform 1.5.7 and official Provider 0.0.73. Complete also passed the standard four-step lifecycle with 5 nodes and 16 disks independently confirmed absent. Bootstrap on all 5 nodes, Spark/Hive TOS queries (10 rows, sum 45), TOS event logs, and History Server reads passed. Updates, replacement, import, Kerberos, and high availability remain unverified.

## 2. Usage

Configure Provider and credentials in the calling root. The supplied VPC naming reference is `source = "terraform-volcenginecc-modules/vpc/volcenginecc"`; EMR uses `terraform-volcenginecc-modules/emr/volcenginecc`. They are different modules. This is the intended EMR publication address, with no released version claimed. Run a local checkout until publication.

```hcl
module "emr" {
  source = "terraform-volcenginecc-modules/emr/volcenginecc"

  cluster_name      = var.cluster_name
  release_version   = var.release_version
  network           = var.network
  ecs_iam_role      = var.ecs_iam_role
  ecs_key_pair_name = var.ecs_key_pair_name
  initial_node_groups = {
    master = {
      name          = "MasterGroup"
      type          = "MASTER"
      instance_type = var.master_instance_type
      node_count    = 1
      system_disk   = { size = 120, volume_type = var.disk_type }
      data_disk     = { size = 80, volume_type = var.disk_type, count = 1 }
    }
    core = {
      name          = "CoreGroup"
      type          = "CORE"
      instance_type = var.worker_instance_type
      node_count    = 2
      system_disk   = { size = 120, volume_type = var.disk_type }
      data_disk     = { size = 200, volume_type = var.disk_type, count = 4 }
    }
  }
}
```

Declare these variables in the calling root. Confirm regional availability of releases, components, instance types, disks, and quotas.

## 3. Examples

| Directory | Scenario | Coverage |
|---|---|---|
| `examples/basic` | Spark/Hadoop offline ETL | HDFS/YARN/SPARK3; 1 Master, 2 Core; private nodes |
| `examples/complete` | Spark/Hive data lake and batch workers | Master/Core/TASK, real Bootstrap reference, Hive warehouses, Spark event logs, tags |

Root and both examples contain `main.tf`, `outputs.tf`, `variables.tf`, `versions.tf`, `README.md`, and `README.zh-CN.md`. Root also has `.gitignore`, `.pre-commit-config.yaml`, `CHANGELOG.md`, `LICENSE`, and `SECURITY.md`. No reusable child module is needed.

## 4. Requirements

| Requirement | Version / condition |
|---|---|
| Engine constraint | `>= 1.5.7, < 2.0.0` |
| Tested Terraform | `1.5.7` |
| Tested OpenTofu | `1.11.8` |
| Minimum Provider | `volcengine/volcenginecc >= 0.0.60` |
| Example Provider | Official `0.0.73`, pinned in both examples |
| Existing dependencies | VPC, Subnet, security group, ECS IAM Role, SSH key pair; complete also needs a private TOS bucket and uploaded script |
| Cloud prerequisites | Enabled EMR, sufficient quotas, supported releases/components and node/disk specifications |

Other engine versions are untested. All groups share one subnet/zone. Caller manages security-group rules and outbound connections. Only POST billing is supported, without public node IPs.

## 5. Providers

| Name | Source | Version |
|---|---|---|
| volcenginecc | `volcengine/volcenginecc` | `>= 0.0.60` |

Root has no Provider configuration, region, credentials, or backend. Use official releases without `dev_overrides`.

## 6. Resources

| Resource | Ownership |
|---|---|
| [volcenginecc_emr_cluster](https://registry.terraform.io/providers/volcengine/volcenginecc/0.0.73/docs/resources/emr_cluster) | `volcenginecc_emr_cluster.this`: cluster and initial Master/Core |
| [volcenginecc_emr_node_group](https://registry.terraform.io/providers/volcengine/volcenginecc/0.0.73/docs/resources/emr_node_group) | `volcenginecc_emr_node_group.task["<key>"]`: independent TASK |

No Data Sources. EMR creates underlying nodes; do not separately declare ECS resources for them. Initial groups and TASK have separate ownership. Network, IAM, keys, and TOS are external.

## 7. Inputs

Exact object definitions and validations are in `variables.tf`.

| Name | Type | Default | Required | Description |
|---|---|---|---|---|
| cluster_name | string | — | yes | Cluster name |
| release_version | string | — | yes | EMR release; determines component versions |
| cluster_type | string | `"Hadoop"` | no | Region-supported cluster type |
| application_names | set(string) | `["HDFS", "YARN", "SPARK3"]` | no | Installed component names |
| project_name | string | `"default"` | no | Project |
| network | object | — | yes | vpc_id, subnet_id, security_group_id, zone_id |
| ecs_iam_role | string | — | yes | Existing ECS IAM Role |
| ecs_key_pair_name | string | — | yes | Existing SSH key pair |
| deploy_mode | string | `"SIMPLE"` | no | SIMPLE / HIGH_AVAILABLE |
| security_mode | string | `"SIMPLE"` | no | Release-supported mode, including KERBEROS where available |
| history_server_mode | string | `"LOCAL"` | no | LOCAL / PHS |
| initial_node_groups | map(object) | — | yes | Exactly one MASTER and one CORE; name, type, instance_type, node_count, system_disk, data_disk |
| task_node_groups | map(object) | `{}` | no | TASK groups; name, instance_type, node_count, system_disk, data_disk |
| bootstrap_scripts | map(object) | `{}` | no | Script name/path, arguments, priority, failure/execution strategy |
| application_configs | map(object) | `{}` | no | Application, metadata connection, file/key/value settings |
| tags | map(string) | `null` | no | Omit by default; explicit empty map requests removal |

Disks specify size/volume_type; data disks also count. Bootstrap must reference uploaded `tos://bucket/key` objects. Nested defaults and constraints are in `variables.tf`.

## 8. Outputs

| Name | Description |
|---|---|
| cluster_id | Cluster ID |
| cluster_state | Provider-reported state |
| applications | Installed components and actual versions |
| task_node_group_ids | Stable TASK key to ID |
| network | Caller-provided references |

## 9. Notes

Treat releases, components, network, Role, deployment/security/history mode, Bootstrap, application settings, and initial groups as creation configuration. Inspect replacement plans before changing them. Local CCAPI Schema marks major fields create-only; published Provider Schema JSON omits RequiresReplace. Exact replacement, name/tag updates, and TASK capacity changes need real State validation. Initial keys do not form independent addresses. Renaming a TASK key deletes/recreates its group; finish jobs and protect data before scaling/removal.

Some creation fields are write-only or Optional+Computed. Empty application settings omit `application_extras`, fixing observed replacement; they do not clear existing settings. Default tags are omitted; explicit `{}` preserves removal intent, whose read-back idempotency remains unverified. Computed-only fields remain Provider-managed; no `ignore_changes` hides drift.

Complete configures private TOS Hive warehouses and Spark event/history paths, without all system logs, TLS collection, retention, or global `log_uri`. Verify connector, Role permissions, settings, and History Server in the target release. PHS alone does not configure TOS logs. Settings and Bootstrap arguments enter configuration/State; exclude credentials.

Provider 0.0.60/0.0.73 expose no autoscaling; adjust TASK manually. Serverless, Studio, Spot/Instance Fleet, and job orchestration are outside scope. HIGH_AVAILABLE and Kerberos are configuration options only; confirm release support and node counts. Neither is cloud-validated.

Import is untested. Follow target Provider documentation and supply creation inputs first. Destroy removes owned cluster/groups; independently confirm EMR/TASK/ECS/disk absence. Caller dependencies and TOS data remain.

```shell
terraform fmt -check -recursive
terraform init
terraform validate
```

For OpenTofu 1.11.8, substitute `tofu` in these commands. Static validation passed on Terraform 1.5.7 and OpenTofu 1.11.8 with official Provider 0.0.60/0.0.73. Basic and complete passed the Terraform 1.5.7 cloud lifecycle with official Provider 0.0.73; complete used an uploaded, hash-verified Bootstrap script. Static validation does not prove Registry resolution or OpenTofu cloud execution. InfraManager, OpenTofu cloud execution, updates, Registry consumption, and publication remain pending.
