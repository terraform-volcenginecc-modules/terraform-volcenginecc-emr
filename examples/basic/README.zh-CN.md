# BASIC EMR 示例

## 1. 概述

本示例创建 1 个 Master 和 2 个 Core 节点组成的私网 Spark/Hadoop 集群，安装 HDFS、YARN 和 SPARK3。调用方需准备同一 VPC 和可用区内的 Subnet、安全组、ECS IAM Role、SSH 密钥对，以及可用的 EMR 发行版本、ECS 规格和磁盘类型。与 complete 相比，本示例不创建 TASK 节点组，也不配置 Hive 和 TOS 数据湖。

## 2. 用法

在 `examples/basic` 目录填写输入并执行：

```shell
terraform init
terraform plan
terraform apply
terraform plan
terraform destroy
```

首次 Plan 用于确认创建范围；Apply 后再次 Plan，预期没有变化。Destroy 前确认当前 State 只包含本示例管理的 EMR 集群，调用方已有网络、IAM Role 和 SSH 密钥对不会被删除。

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
| `module.emr` | 通过 `terraform-volcenginecc-modules/emr/volcenginecc` 创建 EMR 集群及初始 Master/Core 节点组。 |

本示例不直接声明 Resource 或 Data Source。

## 6. 输入

| 名称 | 说明 |
|---|---|
| `region` | 部署地域，同时用于配置 `volcenginecc` Provider。 |
| `cluster_name` | EMR 集群名称。 |
| `release_version` | 目标地域可用且支持 HDFS、YARN、SPARK3 的 EMR 发行版本。 |
| `network` | 已有 `vpc_id`、`subnet_id`、`security_group_id` 和 `zone_id`；Subnet 与可用区需要匹配。 |
| `ecs_iam_role` | 已配置 EMR 所需权限的 ECS IAM Role 名称。 |
| `ecs_key_pair_name` | 已有 ECS SSH 密钥对名称。 |
| `instance_type` | Master/Core 节点共用的、目标可用区内 EMR 支持的 ECS 规格。 |
| `disk_type` | 目标可用区支持的 EMR 磁盘类型。 |

## 7. 输出

| 名称 | 说明 |
|---|---|
| `cluster_id` | 创建的 EMR 集群 ID。 |
| `applications` | Provider 回读的已安装组件和实际版本信息。 |

## 8. 示例

本目录即为 basic 示例，适合先部署最小 Spark/Hadoop 集群。需要 HIVE、独立 TASK 节点组、TOS Hive 仓库或 Spark 事件日志时，使用 complete 示例。

## 9. 说明

- Provider 凭据通过环境变量、共享配置或运行平台的凭据管理能力传入，不写入源码或参数文件。
- Apply 后再次执行 `terraform plan`；只有结果无变化时才满足幂等要求。
- 安全组规则和出站连接由调用方管理。
- 修改发行版本、网络或初始节点组前先查看 Plan，确认是否替换集群。
- `terraform destroy` 删除模块管理的 EMR 集群，保留调用方已有的网络、IAM Role 和 SSH 密钥对。
