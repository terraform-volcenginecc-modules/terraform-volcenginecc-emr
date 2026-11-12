# COMPLETE EMR 示例

## 1. 概述

本示例创建 1 个 Master、2 个 Core 和默认 2 个 TASK 节点，安装 HDFS、YARN、SPARK3 和 HIVE，并把 Hive 仓库及 Spark 事件日志配置到调用方已有的私有 TOS Bucket。与 basic 相比，本示例增加独立 TASK 节点组、TOS 数据湖、标签和可选 Bootstrap。调用方还需准备 TOS 日志目录、访问权限及目标地域支持的规格。

## 2. 用法

### 准备 TOS

Spark 事件日志写入 `tos://your-emr-bucket/logs/spark-events/`，其中 `your-emr-bucket` 替换为实际 Bucket 名称。部署前，用户先创建 TOS Bucket，再确保日志目录存在；TOS connector 使用原生重命名时，还需开启 RenameObject。

可选工具 `prepare-tos.py` 在部署电脑或流水线上完成目录和 RenameObject 准备。它不创建 Bucket，也不操作 EMR 节点：

```shell
python3 prepare-tos.py \
  --bucket "your-emr-bucket" \
  --region "cn-beijing" \
  --enable-rename
```

脚本读取环境变量中的 `VOLCENGINE_ACCESS_KEY`、`VOLCENGINE_SECRET_KEY`。如果已通过控制台完成相同操作，可以跳过；使用 `--check` 可只检查、不修改。

### 按需启用 Bootstrap

Bootstrap 默认关闭。`bootstrap.sh` 是可选案例，用于在每个 EMR 节点创建 `/var/tmp/emr-batch`，不是集群启动的必需脚本，也不操作 TOS。

需要节点初始化时，先将案例脚本或自己的脚本上传到 TOS，再设置：

```hcl
bootstrap_script_path = "tos://your-emr-bucket/bootstrap/bootstrap.sh"
```

集群 ECS IAM Role 必须能读取该对象。省略 `bootstrap_script_path` 或设为 `null` 时不启用 Bootstrap。`prepare-tos.py` 与 `bootstrap.sh` 各自独立，互不调用。

### 执行 Terraform

在 `examples/complete` 目录填写输入并执行：

```shell
terraform init
terraform plan
terraform apply
terraform plan
terraform destroy
```

首次 Plan 用于确认集群、TASK 节点组和 TOS 配置。Apply 后再次 Plan，预期没有变化。Destroy 前完成业务作业并确认删除范围；调用方已有网络、IAM、SSH 密钥对和 TOS 数据不会被删除。

## 3. 依赖要求

| 名称 | 版本 |
|---|---|
| Terraform | `>= 1.5.7, < 2.0.0` |
| `volcengine/volcenginecc` | `= 0.0.73` |

## 4. Providers

| 名称 | 来源 |
|---|---|
| `volcenginecc` | `volcengine/volcenginecc` |

## 5. 资源

| 名称 | 说明 |
|---|---|
| `module.emr` | 通过 `terraform-volcenginecc-modules/emr/volcenginecc` 创建 EMR 集群、初始 Master/Core 组和独立 TASK 组，并配置 Hive 仓库、Spark 事件日志、标签及可选 Bootstrap。 |

本示例不直接声明 Resource 或 Data Source。

## 6. 输入

| 名称 | 说明 |
|---|---|
| `region` | 部署地域，同时用于配置 `volcenginecc` Provider。 |
| `cluster_name` | EMR 集群名称。 |
| `release_version` | 支持 SPARK3、HIVE 和 TOS connector 的 EMR 发行版本。 |
| `network` | 已有 `vpc_id`、`subnet_id`、`security_group_id` 和 `zone_id`；Subnet 与可用区需要匹配。 |
| `ecs_iam_role` | 允许 EMR 访问 TOS 数据、日志及可选 Bootstrap 脚本的 ECS IAM Role。 |
| `ecs_key_pair_name` | 已有 ECS SSH 密钥对名称。 |
| `master_instance_type` | Master 节点 ECS 规格。 |
| `worker_instance_type` | Core 和 TASK 节点共用的 ECS 规格。 |
| `disk_type` | 目标可用区支持的 EMR 磁盘类型。 |
| `tos_bucket_name` | 已有私有 TOS Bucket 名称，不含 `tos://`。 |
| `bootstrap_script_path` | 可选初始化脚本地址。填写 `tos://bucket/key` 时启用 Bootstrap；省略或设为 `null` 时关闭。 |
| `task_node_count` | TASK 节点手动期望容量，默认 `2`；不是自动伸缩策略。 |
| `tags` | 集群标签，默认 `{ scenario = "spark-hive-data-lake" }`。 |

## 7. 输出

| 名称 | 说明 |
|---|---|
| `cluster_id` | 创建的 EMR 集群 ID。 |
| `task_node_group_ids` | TASK 逻辑 key 与节点组 ID 的映射。 |
| `applications` | Provider 回读的已安装组件和实际版本信息。 |
| `data_lake_paths` | 调用方管理的 Hive 托管仓库、外部仓库和 Spark 事件日志路径。 |

## 8. 示例

本目录即为 complete 示例，适合创建带 Hive、独立批处理 Worker 和 TOS 数据湖的集群。只需要最小 Spark/Hadoop 集群时，使用 basic 示例。

## 9. 说明

- Provider 凭据通过环境变量、共享配置或运行平台的凭据管理能力传入，不写入源码或参数文件。
- Apply 后再次执行 `terraform plan`；只有结果无变化时才满足幂等要求。
- `task_node_count` 设置手动期望容量，本示例不配置自动伸缩策略。
- TOS 日志目录是 Spark History 的前置条件，与是否启用 Bootstrap 无关。
- Bootstrap 在应用安装前执行时不能依赖 Hadoop 已安装；脚本参数和应用配置中不应包含凭据。
- 修改初始节点组、发行版本、Bootstrap 或应用配置前先查看 Plan，确认是否替换集群。
- `terraform destroy` 删除模块管理的 EMR 集群和 TASK 节点组，保留调用方已有的网络、IAM、SSH 密钥对和 TOS 数据。
