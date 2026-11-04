# Changelog

## Unreleased

- 参照 VPC 模块整理仓库，统一 root 与 basic/complete 的 outputs.tf 和双语九节 README，移除项目内快捷链接。
- 示例使用 EMR Registry 命名格式，明确 Registry 待发布状态；通过 Terraform 1.5.7 / OpenTofu 1.11.8 双引擎、双 Provider 版本静态验证。
- 提供 Spark/Hadoop/Hive EMR 模块，配置 Master/Core、独立 TASK、Bootstrap 和应用参数，以及 basic、complete 示例。
- 明确 TOS、IAM、网络外部所有权，以及 Worker 自动伸缩和全局系统日志的 Provider 缺口。
- 修复未配置应用扩展时显式空列表导致的集群替换；未配置标签默认省略，保留显式清空标签的意图。
- basic 修复复验通过：创建与核心服务正常，二次 plan No changes，标准 destroy 后逐 ID 确认 3 节点和 12 磁盘全部释放；原始失败记录保留。
- complete 标准生命周期通过：二次 plan No changes，标准 destroy 后逐 ID 确认 5 节点和 16 磁盘全部释放；5 节点 Bootstrap、Spark/Hive TOS 查询、事件日志和 History Server 读取通过。
- 更新/替换、导入、HA/Kerberos、InfraManager、OpenTofu 云验与 Registry 发布尚未验证。
