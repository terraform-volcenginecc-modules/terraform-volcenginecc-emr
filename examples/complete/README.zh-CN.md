# complete

## 1. Overview

Spark/Hive 数据湖与批处理 Worker：1 个 Master、2 个 Core，以及默认 2 个节点的独立 TASK 组。私有 TOS 保存 Hive 托管／外部仓库和 Spark 事件／History 日志。Bootstrap 引用调用方已上传的实际脚本。

## 2. Usage

计划 source 为 `terraform-volcenginecc-modules/emr/volcenginecc`，尚未发布。运行草稿时，在本地检出源码中将 source 改为 `../..`；静态验证仅在临时副本中修改。在被忽略的 `terraform.tfvars` 中填写必填输入；通过 `VOLCENGINE_ACCESS_KEY` / `VOLCENGINE_SECRET_KEY` 或支持的 profile 提供凭据。排除 `dev_overrides` 并使用官方 Provider。

```shell
terraform init -backend=false
terraform validate
terraform plan
terraform apply
terraform plan -detailed-exitcode
terraform destroy
```

OpenTofu 将命令替换为 `tofu`，使用独立目录和 State。这些命令创建计费资源。complete 已使用 Terraform 1.5.7 和官方 Provider 0.0.73 通过云端生命周期；OpenTofu 云端运行尚未验证。

## 3. Examples

相较 `examples/basic`，本示例增加 HIVE、独立 TASK 组、Bootstrap、TOS 应用配置和标签，不执行 Spark/Hive 业务作业。

## 4. Requirements

| 依赖 | 版本／条件 |
|---|---|
| Terraform | `1.5.7` |
| OpenTofu | `1.11.8` |
| 已有依赖 | 匹配的网络、ECS IAM Role、SSH 密钥对、私有 TOS Bucket、已上传的实际 Bootstrap 脚本 |
| 云端条件 | 支持 SPARK3/HIVE 和 TOS connector 的发行版本；匹配的规格与足够配额 |

脚本可使用独立 Bucket。所有对象权限、访问、保留策略和数据清理由调用方管理。

## 5. Providers

| 名称 | 来源 | 版本 |
|---|---|---|
| volcenginecc | `volcengine/volcenginecc` | `= 0.0.73` |

## 6. Resources

| 经模块管理 | 数量 |
|---|---|
| `volcenginecc_emr_cluster` | 1，包含初始 Master/Core 组 |
| `volcenginecc_emr_node_group` | 1 个独立 TASK 组，key 为 `batch` |

示例不创建外部依赖或 TOS 对象。

## 7. Inputs

| 名称 | 类型 | 默认值 | 必填 | 说明 |
|---|---|---|---|---|
| region | string | — | yes | 部署地域 |
| cluster_name | string | — | yes | 集群名称 |
| release_version | string | — | yes | 支持 SPARK3/HIVE 的发行版本 |
| network | object | — | yes | vpc_id、subnet_id、security_group_id、zone_id |
| ecs_iam_role | string | — | yes | 已授权数据／日志／脚本路径的 Role |
| ecs_key_pair_name | string | — | yes | 已有 SSH 密钥对 |
| master_instance_type | string | — | yes | Master ECS 规格 |
| worker_instance_type | string | — | yes | Core/TASK ECS 规格 |
| disk_type | string | — | yes | 支持的 EMR 磁盘类型 |
| tos_bucket_name | string | — | yes | 已有私有 Bucket 名称，不含 tos:// |
| bootstrap_script_path | string | — | yes | 已上传的实际 tos://bucket/key 脚本 |
| task_node_count | number | `2` | no | TASK 手动期望容量 |
| tags | map(string) | `{ scenario = "spark-hive-data-lake" }` | no | 集群标签 |

## 8. Outputs

| 名称 | 说明 |
|---|---|
| cluster_id | EMR 集群 ID |
| task_node_group_ids | TASK key 与节点组 ID 映射 |
| applications | 安装组件及实际版本 |
| data_lake_paths | 调用方拥有的托管／外部仓库和 Spark 事件日志路径 |

## 9. Notes

2026-11-04，complete 使用 Terraform 1.5.7 和官方 Provider 0.0.73，通过 Plan/Apply/二次 plan No changes/标准 Destroy，5 个节点和 16 块磁盘均独立回查确认释放。5 节点 Bootstrap、Spark/Hive TOS 查询（10 行、总和 45）、TOS 事件日志和 History Server 读取通过。TASK 更新／删除尚未验证。Spark 事件日志不等于全部 EMR 系统日志，未配置 TLS 采集。

Provider 0.0.60 和 0.0.73 未暴露 EMR 自动伸缩策略。通过修改 `task_node_count` 手动调整期望容量，再验证二次 plan No changes；不应让另一系统同时管理该容量。删除 `batch` 应仅删除对应 TASK 组，该行为需真实 State 验证。修改初始组、发行版本或 Bootstrap 前查看替换计划。

脚本、参数和应用配置不应包含凭据。destroy 清理模块拥有的集群和 TASK 组；独立确认 EMR、ECS 和磁盘无残留，保留调用方依赖和 TOS 数据。
