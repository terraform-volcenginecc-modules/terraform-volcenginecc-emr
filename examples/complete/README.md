# COMPLETE EMR Example

## 1. Overview

This example creates 1 Master, 2 Core, and 2 TASK nodes by default, installs HDFS, YARN, SPARK3, and HIVE, and configures Hive warehouses and Spark event logs in an existing private TOS bucket. Compared with basic, it adds an independent TASK group, TOS data-lake settings, tags, and optional Bootstrap. The caller also prepares TOS log prerequisites, permissions, and supported regional specifications.

## 2. Usage

### Prepare TOS

Spark event logs are written to `tos://your-emr-bucket/logs/spark-events/`; replace `your-emr-bucket` with the actual bucket name. Before deployment, create the TOS bucket and event-log directory. When the TOS connector uses native renaming, enable RenameObject.

The optional `prepare-tos.py` runs from the deployment workstation or pipeline and prepares the directory and RenameObject. It does not create a bucket or operate on EMR nodes:

```shell
python3 prepare-tos.py \
  --bucket "your-emr-bucket" \
  --region "cn-beijing" \
  --enable-rename
```

The script reads `VOLCENGINE_ACCESS_KEY` and `VOLCENGINE_SECRET_KEY` from the environment. Skip it if the same preparation was completed through the console. Use `--check` for read-only verification.

### Enable Bootstrap When Needed

Bootstrap is disabled by default. `bootstrap.sh` is an optional example that creates `/var/tmp/emr-batch` on every EMR node. It is not required to start the cluster and does not operate on TOS.

For node initialization, upload the example or your own script to TOS, then set:

```hcl
bootstrap_script_path = "tos://your-emr-bucket/bootstrap/bootstrap.sh"
```

The cluster ECS IAM Role must be able to read the object. Omit `bootstrap_script_path` or set it to `null` to disable Bootstrap. `prepare-tos.py` and `bootstrap.sh` are independent and do not call each other.

### Run Terraform

Configure inputs and run these commands from `examples/complete`:

```shell
terraform init
terraform plan
terraform apply
terraform plan
terraform destroy
```

Use the first Plan to review the cluster, TASK group, and TOS settings. The Plan after Apply should show no changes. Finish business jobs and review the deletion scope before Destroy. Existing network, IAM, SSH key-pair, and TOS data remain.

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
| `module.emr` | Uses `terraform-volcenginecc-modules/emr/volcenginecc` to create the EMR cluster, initial Master/Core groups, and independent TASK group, and to configure Hive warehouses, Spark event logs, tags, and optional Bootstrap. |

This example declares no Resource or Data Source directly.

## 6. Inputs

| Name | Description |
|---|---|
| `region` | Deployment region, also used to configure the `volcenginecc` Provider. |
| `cluster_name` | EMR cluster name. |
| `release_version` | EMR release supporting SPARK3, HIVE, and the TOS connector. |
| `network` | Existing `vpc_id`, `subnet_id`, `security_group_id`, and `zone_id`; the Subnet and zone must match. |
| `ecs_iam_role` | ECS IAM Role allowing EMR to access TOS data, logs, and the optional Bootstrap script. |
| `ecs_key_pair_name` | Existing ECS SSH key-pair name. |
| `master_instance_type` | Master-node ECS specification. |
| `worker_instance_type` | ECS specification shared by Core and TASK nodes. |
| `disk_type` | EMR disk type supported in the target zone. |
| `tos_bucket_name` | Existing private TOS bucket name without `tos://`. |
| `bootstrap_script_path` | Optional initialization-script address. Provide `tos://bucket/key` to enable Bootstrap; omit it or set it to `null` to disable Bootstrap. |
| `task_node_count` | Manual desired TASK capacity, default `2`; not an autoscaling policy. |
| `tags` | Cluster tags, default `{ scenario = "spark-hive-data-lake" }`. |

## 7. Outputs

| Name | Description |
|---|---|
| `cluster_id` | ID of the created EMR cluster. |
| `task_node_group_ids` | TASK logical key to node-group ID mapping. |
| `applications` | Installed application and actual version information returned by the Provider. |
| `data_lake_paths` | Caller-managed Hive managed-warehouse, external-warehouse, and Spark event-log paths. |

## 8. Example

This directory contains the complete example for a cluster with Hive, independent batch workers, and a TOS data lake. Use basic when only a minimal Spark/Hadoop cluster is required.

## 9. Notes

- Supply Provider credentials through environment variables, shared configuration, or the runtime platform's credential manager. Do not store them in source or variable files.
- Run `terraform plan` again after Apply. Idempotence requires the final Plan to show no changes.
- `task_node_count` sets manual desired capacity; this example does not configure an autoscaling policy.
- The TOS event-log directory is a Spark History prerequisite independent of Bootstrap.
- Bootstrap cannot rely on Hadoop when it runs before application installation. Do not include credentials in script arguments or application settings.
- Review the Plan before changing initial node groups, the release, Bootstrap, or application settings to identify cluster replacement.
- `terraform destroy` removes the module-managed EMR cluster and TASK group while preserving caller-owned network, IAM, SSH key pair, and TOS data.
