# basic

## 1. Overview

Spark/Hadoop 离线 ETL：1 个 Master、2 个 Core，HDFS/YARN/SPARK3，按量计费，私网节点。使用已有网络、IAM Role 和 SSH 密钥对。

## 2. Usage

计划 source 为 `terraform-volcenginecc-modules/emr/volcenginecc`，尚未发布。运行草稿时，在本地检出源码中将模块 source 改为 `../..`；静态脚本仅在临时副本中修改。在被忽略的 `terraform.tfvars` 中填写所有必填输入。通过 `VOLCENGINE_ACCESS_KEY` / `VOLCENGINE_SECRET_KEY` 或支持的 profile 提供 Provider 凭据。排除 `dev_overrides`，确保使用官方 Provider。

```shell
terraform init -backend=false
terraform validate
terraform plan
terraform apply
terraform plan -detailed-exitcode
terraform destroy
```

OpenTofu 将命令中的 `terraform` 替换为 `tofu`，使用独立目录和 State。这些命令创建计费资源；OpenTofu 云端运行尚未验证。

## 3. Examples

本目录为基础场景。`examples/complete` 增加 TASK Worker、Bootstrap、Hive 仓库和 Spark 事件日志。

## 4. Requirements

| 依赖 | 版本／条件 |
|---|---|
| Terraform | `1.5.7` |
| OpenTofu | `1.11.8` |
| 已有依赖 | 同 VPC 网络、匹配的 Subnet／可用区／安全组、ECS IAM Role、SSH 密钥对 |
| 云端条件 | 已开通 EMR；支持的发行版本、组件、ECS／磁盘规格；足够配额 |

## 5. Providers

| 名称 | 来源 | 版本 |
|---|---|---|
| volcenginecc | `volcengine/volcenginecc` | `= 0.0.73` |

## 6. Resources

| 经模块管理 | 数量 |
|---|---|
| `volcenginecc_emr_cluster` | 1，包含初始 Master/Core 组 |

示例不创建独立 TASK 组或外部依赖。

## 7. Inputs

| 名称 | 类型 | 默认值 | 必填 | 说明 |
|---|---|---|---|---|
| region | string | — | yes | 部署地域 |
| cluster_name | string | — | yes | 集群名称 |
| release_version | string | — | yes | 地域支持的 EMR 发行版本 |
| network | object | — | yes | vpc_id、subnet_id、security_group_id、zone_id |
| ecs_iam_role | string | — | yes | 已授权的 ECS Role |
| ecs_key_pair_name | string | — | yes | 已有 SSH 密钥对 |
| instance_type | string | — | yes | EMR 支持的 ECS 规格 |
| disk_type | string | — | yes | 支持的 EMR 磁盘类型 |

## 8. Outputs

| 名称 | 说明 |
|---|---|
| cluster_id | EMR 集群 ID |
| applications | 安装组件及实际版本 |

## 9. Notes

2026-11-04，Terraform 1.5.7 和官方 Provider 0.0.73 通过创建及核心服务启动。修复空 `application_extras` 回读差异后，二次 plan 返回 No changes（退出 0）。标准 destroy 成功，已独立回查确认 3 个 ECS 节点和 12 块磁盘全部释放。业务作业及其他部署／安全模式未验证。

安全组规则和出站连接由调用方管理。不要在仓库保存凭据。二次 plan 必须返回 0；destroy 后独立查询 EMR、ECS 和磁盘确认无残留。调用方依赖保留。
