# Changelog

## Unreleased

- 提供 Spark/Hadoop/Hive EMR 模块，配置 Master/Core、独立 TASK、Bootstrap 和应用参数，以及 basic、complete 示例。
- 示例通过 `terraform-volcenginecc-modules/emr/volcenginecc` 引用模块，提供双语使用文档。
- 网络、IAM、SSH 密钥对及 TOS 资源由调用方管理。
- 修复未配置应用扩展时显式空列表导致的集群替换；未配置标签默认省略，保留显式清空标签的意图。
