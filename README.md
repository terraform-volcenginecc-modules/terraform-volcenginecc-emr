# terraform-volcenginecc-emr

Creates and manages Volcengine E-MapReduce (EMR) clusters.

## 1. Overview

This module creates one pay-as-you-go EMR cluster with initial Master/Core node groups for Spark, Hadoop, Hive, offline ETL, data lakes, and batch processing. It can also manage independent TASK groups and configure the release, applications, disks, Bootstrap actions, application settings, and tags. The caller owns the VPC, Subnet, security group, ECS IAM Role, SSH key pair, TOS objects, and business jobs.

## 2. Usage

Prepare a Subnet and security group in the same VPC and availability zone, an ECS IAM Role, and an SSH key pair. Confirm that the target region supports the selected EMR release, applications, ECS types, and disk types.

```hcl
provider "volcenginecc" {
  region = var.region
}

module "emr" {
  source = "terraform-volcenginecc-modules/emr/volcenginecc"

  cluster_name      = "data-platform"
  release_version   = "3.19.0"
  ecs_iam_role      = "VEECSforEMRRole"
  ecs_key_pair_name = "emr-keypair"

  network = {
    vpc_id            = "vpc-xxxxxxxx"
    subnet_id         = "subnet-xxxxxxxx"
    security_group_id = "sg-xxxxxxxx"
    zone_id           = "cn-beijing-a"
  }

  initial_node_groups = {
    master = {
      name          = "MasterGroup"
      type          = "MASTER"
      instance_type = "ecs.r1ie.xlarge"
      node_count    = 1
      system_disk   = { size = 120, volume_type = "ESSD_FlexPL" }
      data_disk     = { size = 80, volume_type = "ESSD_FlexPL", count = 1 }
    }
    core = {
      name          = "CoreGroup"
      type          = "CORE"
      instance_type = "ecs.r1ie.xlarge"
      node_count    = 2
      system_disk   = { size = 120, volume_type = "ESSD_FlexPL" }
      data_disk     = { size = 200, volume_type = "ESSD_FlexPL", count = 4 }
    }
  }
}
```

Inject Provider credentials through environment variables, a shared profile, or the calling platform's credential manager. Do not put credentials in module inputs.

## 3. Examples

- basic: Creates a private Spark/Hadoop cluster with 1 Master, 2 Core nodes, HDFS, YARN, and SPARK3. It uses an existing network, IAM Role, and SSH key pair.
- complete: Adds HIVE, an independent TASK group, TOS Hive warehouses, Spark event logs, and tags.
    - `prepare-tos.py`: An optional TOS preparation tool included with complete. Run it from a deployment workstation or pipeline to check an existing bucket, create the Spark event-log directory, and enable RenameObject when requested. Skip it if these steps were completed through the console.
    - `bootstrap.sh`: A Bootstrap example included with complete, not a script required to start the cluster. To demonstrate node initialization, upload it to your TOS bucket and set `bootstrap_script_path`; EMR then runs it on every node to create `/var/tmp/emr-batch`. Omit it when no node initialization is needed.
    - The files are independent and do not call each other.

Both examples reference the module through its Registry source. Enter the selected example directory, provide its inputs, and run `terraform init`, `terraform plan`, and `terraform apply`.

## 4. Requirements

| Name | Version |
|---|---|
| Terraform / OpenTofu | `>= 1.5.7, < 2.0.0` |
| `volcengine/volcenginecc` | `>= 0.0.60` |

## 5. Providers

| Name | Source |
|---|---|
| `volcenginecc` | `volcengine/volcenginecc` |

The module does not configure a Provider alias, region, credentials, or backend. Configure them in the calling root module.

## 6. Resources

| Mode | Type | Name |
|---|---|---|
| Create | `volcenginecc_emr_cluster` | [`volcenginecc_emr_cluster.this`](https://registry.terraform.io/providers/volcengine/volcenginecc/latest/docs/resources/emr_cluster) |
| Create | `volcenginecc_emr_node_group` | [`volcenginecc_emr_node_group.task`](https://registry.terraform.io/providers/volcengine/volcenginecc/latest/docs/resources/emr_node_group) |

The module reads no Data Sources. EMR creates the underlying ECS instances; do not separately declare ECS resources for the same nodes.

## 7. Inputs

| Name | Type | Default | Required in create mode | Description |
|---|---|---|---|---|
| `cluster_name` | `string` | None | Yes | Non-empty cluster name. |
| `release_version` | `string` | None | Yes | Region-supported EMR release in `x.y.z` format; changing it may replace the cluster. |
| `cluster_type` | `string` | `"Hadoop"` | No | Cluster type supported by the selected region and release. |
| `application_names` | `set(string)` | `["HDFS", "YARN", "SPARK3"]` | No | Applications to install. At least one non-empty name is required; the release determines application versions. |
| `project_name` | `string` | `"default"` | No | Project name using letters, numbers, underscores, periods, and hyphens, with length 1–64. |
| `network` | `object({ vpc_id = string, subnet_id = string, security_group_id = string, zone_id = string })` | None | Yes | Caller-managed VPC, same-zone Subnet, security group, and availability zone; all fields must be non-empty. |
| `ecs_iam_role` | `string` | None | Yes | Existing ECS IAM Role. The caller grants EMR permissions and access to required TOS paths. |
| `ecs_key_pair_name` | `string` | None | Yes | Existing ECS SSH key pair; the module does not accept a plaintext node password. |
| `deploy_mode` | `string` | `"SIMPLE"` | No | `SIMPLE` or `HIGH_AVAILABLE`; configure node counts required by the selected release. |
| `security_mode` | `string` | `"SIMPLE"` | No | EMR security mode supported by the selected release. |
| `history_server_mode` | `string` | `"LOCAL"` | No | `LOCAL` or `PHS`; the caller prepares services required by PHS. |
| `initial_node_groups` | `map(object)` | None | Yes | Creation-time Master/Core groups. Must contain exactly one `MASTER` and one `CORE`; each group has `name`, `type`, `instance_type`, `node_count`, `system_disk`, and `data_disk`. |
| `task_node_groups` | `map(object)` | `{}` | No | Independent TASK groups. A stable map key forms the resource address; each group has `name`, `instance_type`, `node_count`, `system_disk`, and `data_disk`. |
| `bootstrap_scripts` | `map(object)` | `{}` | No | Optional node initialization scripts. Each item has `script_name`, `script_path`, and optional `script_args`, `priority`, `execution_moment`, and `execution_fail_strategy`. Upload scripts to `tos://bucket/key` first. |
| `application_configs` | `map(object)` | `{}` | No | Cluster-level application settings. Each item has `application_name`, optional connection settings, and a config map of `file`, `key`, and `value`; the application must be present in `application_names`. |
| `tags` | `map(string)` | `null` | No | Cluster tags. `null` omits tag configuration; explicit `{}` requests removal. |

Node counts must be integers from 1 to 1000. System and data disk sizes must be integer GiB values from 60 to 2048, and each group must have 1–15 data disks. Initial and TASK group names must be globally unique.

## 8. Outputs

| Name | Type | Description |
|---|---|---|
| `cluster_id` | `string` | ID of the created EMR cluster. |
| `cluster_state` | `string` | Cluster state returned by the Provider. |
| `applications` | `set(object)` | Installed application details returned by the Provider, including names, states, versions, directories, and runtime users. |
| `task_node_group_ids` | `map(string)` | TASK logical key to node-group ID mapping; empty when no TASK groups are configured. |
| `network` | `object` | Caller-provided VPC, Subnet, security-group, and availability-zone references for downstream composition. |

## 9. Notes

- The module manages the EMR cluster and independent TASK groups. The caller manages network, IAM Role, SSH key pair, TOS bucket, objects, and business data.
- Changing the release, applications, network, deployment/security/history modes, Bootstrap actions, application settings, or initial node groups may replace the cluster. Review the Terraform plan and protect data before disruptive changes.
- TASK map keys form resource addresses. Renaming a key deletes the old group and creates a new one. Changing `node_count` sets manual desired capacity; this module does not configure autoscaling policies.
- Bootstrap is disabled by default. When enabled, the caller uploads the script to TOS first. Bootstrap arguments and application settings enter Terraform configuration and State, so keep credentials out of them.
- The complete example stores Hive data and Spark event logs in TOS. Prepare the event directory and Role permissions before deployment. When the TOS connector uses native renaming, enable RenameObject; it is incompatible with enabled or suspended bucket versioning.
- `prepare-tos.py` does not create a bucket. It checks an existing bucket, creates the Spark event-log directory, and enables RenameObject when requested. Skip it if these prerequisites were completed through the console or another tool.
- Run a normal `terraform plan` after deployment and confirm that no changes remain. Finish business jobs before destroy; `terraform destroy` removes the module-owned cluster and TASK groups while preserving caller-owned dependencies and TOS data.
