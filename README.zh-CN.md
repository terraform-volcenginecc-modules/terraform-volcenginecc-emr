# terraform-volcenginecc-emr

创建和管理火山引擎 E-MapReduce（EMR）集群。

## 1. 概述（Overview）

本模块面向 Spark、Hadoop、Hive 离线 ETL、数据湖计算和批处理场景，创建一个按量付费 EMR 集群及初始 Master/Core 节点组，并可管理独立 TASK 节点组。调用方可配置发行版本、组件、磁盘、Bootstrap、应用参数和标签；VPC、Subnet、安全组、ECS IAM Role、SSH 密钥对、TOS 对象及业务作业由调用方管理。

## 2. 用法（Usage）

调用方需要准备同一 VPC 和可用区内的 Subnet、安全组、ECS IAM Role、SSH 密钥对，并确认目标地域支持所选 EMR 发行版本、组件、ECS 规格和磁盘类型。

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

Provider 凭据通过环境变量、共享配置文件或调用平台的凭据管理能力注入，不要写入 Module 参数。

## 3. 示例（Examples）

- basic：创建 1 个 Master 和 2 个 Core 的私网 Spark/Hadoop 集群，安装 HDFS、YARN 和 SPARK3，依赖已有网络、IAM Role 和 SSH 密钥对。
- complete：在 basic 基础上增加 HIVE、独立 TASK 组、TOS Hive 仓库、Spark 事件日志和标签。
    - `prepare-tos.py`：随 complete 提供的可选 TOS 准备工具。在部署电脑或流水线上运行，用于检查已有 Bucket、创建 Spark 事件日志目录，并按需开启 RenameObject。已通过控制台完成这些操作时可以跳过。
    - `bootstrap.sh`：随 complete 提供的 Bootstrap 示例脚本，不是集群启动的必需脚本。需要演示节点初始化时，用户先把它上传到自己的 TOS，再填写 `bootstrap_script_path`；EMR 会在各节点执行它并创建 `/var/tmp/emr-batch`。没有节点初始化需求时无需上传或配置。
    - 两个文件各自独立，互不调用。

两个示例都通过 Registry 地址引用模块。进入对应示例目录，填写输入后执行 `terraform init`、`terraform plan` 和 `terraform apply`。

## 4. 版本要求（Requirements）

| 名称 | 版本 |
|---|---|
| Terraform / OpenTofu | `>= 1.5.7, < 2.0.0` |
| `volcengine/volcenginecc` | `>= 0.0.60` |

## 5. Providers（Providers）

| 名称 | 来源 |
|---|---|
| `volcenginecc` | `volcengine/volcenginecc` |

模块不配置 Provider alias、地域、凭据或 backend，这些内容由调用方 root 管理。

## 6. 资源（Resources）

| 模式 | 类型 | 名称 |
|---|---|---|
| 创建 | `volcenginecc_emr_cluster` | [`volcenginecc_emr_cluster.this`](https://registry.terraform.io/providers/volcengine/volcenginecc/latest/docs/resources/emr_cluster) |
| 创建 | `volcenginecc_emr_node_group` | [`volcenginecc_emr_node_group.task`](https://registry.terraform.io/providers/volcengine/volcenginecc/latest/docs/resources/emr_node_group) |

模块不读取 Data Source。EMR 服务负责创建底层 ECS 节点；不要为同一批节点另行声明 ECS 资源。

## 7. 输入（Inputs）

| 名称 | 类型 | 默认值 | 创建模式下是否必填 | 说明 |
|---|---|---|---|---|
| `cluster_name` | `string` | 无 | 是 | 集群名称，不能为空。 |
| `release_version` | `string` | 无 | 是 | 地域可用的 EMR 发行版本，格式为 `x.y.z`；修改可能重建集群。 |
| `cluster_type` | `string` | `"Hadoop"` | 否 | 地域和发行版本支持的集群类型。 |
| `application_names` | `set(string)` | `["HDFS", "YARN", "SPARK3"]` | 否 | 安装组件集合，至少包含一个非空名称；组件版本由发行版本决定。 |
| `project_name` | `string` | `"default"` | 否 | 资源所属项目，允许字母、数字、下划线、点和连字符，长度 1–64。 |
| `network` | `object({ vpc_id = string, subnet_id = string, security_group_id = string, zone_id = string })` | 无 | 是 | 调用方管理的 VPC、同可用区 Subnet、安全组和可用区，四个字段均不能为空。 |
| `ecs_iam_role` | `string` | 无 | 是 | 已有 ECS IAM Role 名称，由调用方授予 EMR 及所需 TOS 路径权限。 |
| `ecs_key_pair_name` | `string` | 无 | 是 | 已有 ECS SSH 密钥对名称；模块不接收节点明文密码。 |
| `deploy_mode` | `string` | `"SIMPLE"` | 否 | `SIMPLE` 或 `HIGH_AVAILABLE`；高可用节点数量按目标发行版本要求配置。 |
| `security_mode` | `string` | `"SIMPLE"` | 否 | 目标发行版本支持的 EMR 安全模式。 |
| `history_server_mode` | `string` | `"LOCAL"` | 否 | `LOCAL` 或 `PHS`；PHS 所需外部服务由调用方准备。 |
| `initial_node_groups` | `map(object)` | 无 | 是 | 创建期 Master/Core 组；必须恰好包含一个 `MASTER` 和一个 `CORE`。每组包含 `name`、`type`、`instance_type`、`node_count`、`system_disk`、`data_disk`。 |
| `task_node_groups` | `map(object)` | `{}` | 否 | 独立 TASK 组。稳定 map key 对应资源地址；每组包含 `name`、`instance_type`、`node_count`、`system_disk`、`data_disk`。 |
| `bootstrap_scripts` | `map(object)` | `{}` | 否 | 可选节点初始化脚本。每项包含 `script_name`、`script_path`，可选 `script_args`、`priority`、`execution_moment`、`execution_fail_strategy`；脚本需预先上传到 `tos://bucket/key`。 |
| `application_configs` | `map(object)` | `{}` | 否 | 集群级组件配置。每项包含 `application_name`、可选连接信息及由 `file`、`key`、`value` 组成的配置 map；组件必须包含在 `application_names` 中。 |
| `tags` | `map(string)` | `null` | 否 | 集群标签；`null` 表示不配置，显式 `{}` 表示请求清空。 |

节点数量必须为 1–1000 的整数；系统盘和数据盘容量必须为 60–2048 GiB 的整数；每组数据盘数量必须为 1–15。初始组和 TASK 组名称必须全局唯一。

## 8. 输出（Outputs）

| 名称 | 类型 | 说明 |
|---|---|---|
| `cluster_id` | `string` | 创建的 EMR 集群 ID。 |
| `cluster_state` | `string` | Provider 回读的集群状态。 |
| `applications` | `set(object)` | Provider 回读的已安装组件信息，包括组件名称、状态、版本、目录和运行用户等字段。 |
| `task_node_group_ids` | `map(string)` | 调用方 TASK 逻辑 key 到节点组 ID 的映射；未配置 TASK 时为空 map。 |
| `network` | `object` | 调用方传入的 VPC、Subnet、安全组和可用区引用，供下游组合使用。 |

## 9. 其他说明（Notes）

- 模块管理 EMR 集群及独立 TASK 组；网络、IAM Role、SSH 密钥对、TOS Bucket、对象和业务数据由调用方管理。
- 修改发行版本、组件、网络、部署模式、安全模式、History 模式、Bootstrap、应用配置或初始节点组可能替换集群。应用前检查 Terraform plan，并在可能中断业务时先完成作业和保护数据。
- TASK map key 形成资源地址。修改 key 会删除旧节点组并创建新节点组；调整 `node_count` 表示手动期望容量，本模块不配置自动伸缩策略。
- Bootstrap 默认关闭。启用时，脚本必须由调用方预先上传到 TOS；脚本参数和应用配置会进入 Terraform 配置及 State，不应包含凭据。
- complete 示例使用 TOS 保存 Hive 数据及 Spark 事件日志。部署前需准备日志目录及 Role 权限；TOS connector 使用原生重命名时还需开启 RenameObject，该功能与已开启或暂停的 Bucket 版本控制互斥。
- `prepare-tos.py` 不创建 Bucket，只负责检查已有 Bucket、创建 Spark 事件日志目录并按需开启 RenameObject。调用方已通过控制台或其他工具完成这些操作时，不需要运行该脚本。
- 部署完成后再次执行正常的 `terraform plan`，确认没有变化。销毁前先完成业务作业；`terraform destroy` 删除模块管理的集群和 TASK 组，保留调用方外部依赖及 TOS 数据。
