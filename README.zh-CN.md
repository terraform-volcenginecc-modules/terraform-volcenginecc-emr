# terraform-volcenginecc-emr

## 1. Overview

面向 Spark/Hadoop/Hive 离线 ETL、数据湖计算和批处理的 EMR 模块。管理一个按量付费集群、初始 Master/Core 节点组及可选的独立 TASK 组。可配置发行版本、组件、磁盘、Bootstrap 脚本、应用设置和标签。网络、IAM、SSH 密钥对、TOS 对象及业务作业由调用方管理。

状态：**draft，Registry 尚未发布**。2026-11-04，basic 使用 Terraform 1.5.7 和官方 Provider 0.0.73，通过创建、核心服务启动、二次 plan No changes 及标准 destroy；已回查确认 3 个节点和 12 块磁盘全部释放。complete 也通过标准四步生命周期，5 个节点和 16 块磁盘独立回查全部释放。5 节点 Bootstrap、Spark/Hive TOS 查询（10 行、总和 45）、TOS 事件日志和 History Server 读取通过。更新、替换、导入、Kerberos 和高可用尚未验证。

## 2. Usage

在调用方 root 配置 Provider 和凭据。用户提供的 VPC Registry 命名格式为 `source = "terraform-volcenginecc-modules/vpc/volcenginecc"`；本 EMR 模块使用 `terraform-volcenginecc-modules/emr/volcenginecc`，两者是不同模块。下方 EMR 地址是计划发布地址，不声明已有发布版本；发布前运行需使用本地检出源码。

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

调用方 root 需声明引用的变量。确认发行版本、组件组合、ECS 规格、磁盘及配额在目标地域可用。

## 3. Examples

| 目录 | 场景 | 覆盖 |
|---|---|---|
| `examples/basic` | Spark/Hadoop 离线 ETL | HDFS、YARN、SPARK3；1 个 Master、2 个 Core；私网节点 |
| `examples/complete` | Spark/Hive 数据湖与批处理 Worker | Master/Core/TASK、实际 Bootstrap 脚本引用、Hive 仓库、Spark 事件日志、标签 |

每个示例包含 `main.tf`、`outputs.tf`、`variables.tf`、`versions.tf`、`README.md` 和 `README.zh-CN.md`。根目录使用相同文件名，并包含 `.gitignore`、`.pre-commit-config.yaml`、`CHANGELOG.md`、`LICENSE` 和 `SECURITY.md`。当前无需复用子模块。

## 4. Requirements

| 依赖 | 版本／条件 |
|---|---|
| 引擎约束 | `>= 1.5.7, < 2.0.0` |
| 已验证 Terraform | `1.5.7` |
| 已验证 OpenTofu | `1.11.8` |
| 最低 Provider | `volcengine/volcenginecc >= 0.0.60` |
| 示例 Provider | 官方 `0.0.73`，两个示例均固定 |
| 已有依赖 | VPC、Subnet、安全组、ECS IAM Role、SSH 密钥对；complete 还需私有 TOS Bucket 和已上传脚本 |
| 云端条件 | 已开通 EMR、足够配额、支持的发行版本／组件及节点／磁盘规格 |

引擎范围允许两个指定引擎，其他版本未测试。所有节点组使用同一子网和可用区。安全组规则及出站连接由调用方管理。仅支持 POST 按量计费，不创建节点公网 IP。

## 5. Providers

| 名称 | 来源 | 版本 |
|---|---|---|
| volcenginecc | `volcengine/volcenginecc` | `>= 0.0.60` |

root 模块不包含 Provider 配置、地域、凭据或 backend。验证必须使用官方发布版本，并排除 `dev_overrides`。

## 6. Resources

| 资源 | 所有权 |
|---|---|
| [volcenginecc_emr_cluster](https://registry.terraform.io/providers/volcengine/volcenginecc/0.0.73/docs/resources/emr_cluster) | `volcenginecc_emr_cluster.this`：集群及初始 Master/Core 配置 |
| [volcenginecc_emr_node_group](https://registry.terraform.io/providers/volcengine/volcenginecc/0.0.73/docs/resources/emr_node_group) | `volcenginecc_emr_node_group.task["<key>"]`：独立 TASK 组 |

不使用 Data Source。底层节点由 EMR 创建，不应为同一批节点额外声明 ECS 资源。初始组与独立 TASK 组分别管理。VPC、Subnet、安全组、IAM、SSH 密钥对和 TOS 是外部依赖。

## 7. Inputs

精确对象定义与校验位于 `variables.tf`。

| 名称 | 类型 | 默认值 | 必填 | 说明 |
|---|---|---|---|---|
| cluster_name | string | — | yes | 集群名称 |
| release_version | string | — | yes | EMR 发行版本，决定组件版本 |
| cluster_type | string | `"Hadoop"` | no | 地域支持的集群类型 |
| application_names | set(string) | `["HDFS", "YARN", "SPARK3"]` | no | 安装组件名称 |
| project_name | string | `"default"` | no | 项目 |
| network | object | — | yes | vpc_id、subnet_id、security_group_id、zone_id |
| ecs_iam_role | string | — | yes | 已有 ECS IAM Role 名称 |
| ecs_key_pair_name | string | — | yes | 已有 SSH 密钥对名称 |
| deploy_mode | string | `"SIMPLE"` | no | SIMPLE / HIGH_AVAILABLE |
| security_mode | string | `"SIMPLE"` | no | 发行版本支持的安全模式，包括可用时的 KERBEROS |
| history_server_mode | string | `"LOCAL"` | no | LOCAL / PHS |
| initial_node_groups | map(object) | — | yes | 恰好一个 MASTER 和一个 CORE；name、type、instance_type、node_count、system_disk、data_disk |
| task_node_groups | map(object) | `{}` | no | TASK 组；name、instance_type、node_count、system_disk、data_disk |
| bootstrap_scripts | map(object) | `{}` | no | 脚本名称／路径、参数、优先级、失败／执行策略 |
| application_configs | map(object) | `{}` | no | 组件、元数据连接、文件／键／值配置 |
| tags | map(string) | `null` | no | 默认省略；显式空 map 表达清空标签 |

磁盘对象指定 size 和 volume_type，数据盘还需 count。Bootstrap 路径必须引用已上传的 `tos://bucket/key` 对象。嵌套可选默认值与约束见 `variables.tf`。

## 8. Outputs

| 名称 | 说明 |
|---|---|
| cluster_id | 集群 ID |
| cluster_state | Provider 回读的集群状态 |
| applications | 安装组件及实际版本 |
| task_node_group_ids | 稳定 TASK 逻辑 key 与节点组 ID 映射 |
| network | 调用方传入的网络引用 |

## 9. Notes

将发行版本、组件、网络、Role、部署／安全／History 模式、Bootstrap、应用设置和初始组视为创建配置，修改前查看替换计划。本地 CCAPI Schema 将主要字段标为 create-only，发布 Provider Schema JSON 不暴露 RequiresReplace。精确替换行为、名称／标签更新与 TASK 容量更新仍需有真实 State 的 plan 验证。初始 map key 不形成独立资源地址。TASK key 改名会删除并重建该组；扩缩容或删除前应完成作业并保护数据。

部分创建字段为 write-only 或 Optional+Computed。空应用配置转换为省略 `application_extras`，修复已观察到的空列表替换问题；此行为不清除已有组件设置。默认 tags 省略，显式 `{}` 保留清空意图，其回读幂等性未验证。Computed-only 字段由 Provider 管理，模块不使用 `ignore_changes` 掩盖漂移。

complete 配置私有 TOS Hive 仓库和 Spark 事件／History 路径，不包含全部 EMR 系统日志、TLS 采集、保留策略或全局 `log_uri`。需实测目标版本的 TOS connector、Role 权限、组件配置及 History Server 行为。PHS 本身不配置 TOS 日志。应用配置和 Bootstrap 参数会进入配置与 State，不应放入凭据。

Provider 0.0.60 和 0.0.73 未暴露自动伸缩，TASK 容量手动调整。Serverless、Studio、Spot/Instance Fleet 和作业编排不在范围内。HIGH_AVAILABLE 和 Kerberos 仅提供配置入口，需确认支持的发行版本及节点数量，尚未云端验证。

未测试 import。导入集群或 TASK 前应遵循目标 Provider 文档并补齐创建输入。destroy 清理模块拥有的节点组和集群；通过独立查询确认 EMR、TASK、ECS、磁盘均无残留。调用方依赖及 TOS 数据保留。

```shell
terraform fmt -check -recursive
terraform init
terraform validate
```

OpenTofu 1.11.8 将上述命令中的 `terraform` 替换为 `tofu`。Terraform 1.5.7 和 OpenTofu 1.11.8 均通过官方 Provider 0.0.60/0.0.73 的静态验证。basic 和 complete 使用 Terraform 1.5.7、官方 Provider 0.0.73 通过云端生命周期；complete 使用真实上传并核对哈希的 Bootstrap 脚本。静态验证不证明 Registry 可解析或 OpenTofu 云端运行通过；InfraManager、OpenTofu 云验、更新、Registry 消费及发布尚未完成。
