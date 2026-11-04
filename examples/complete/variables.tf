variable "region" {
  description = "部署地域。"
  type        = string
}
variable "cluster_name" {
  description = "集群名称。"
  type        = string
}
variable "release_version" {
  description = "支持 SPARK3 和 HIVE 的 EMR 发行版本。"
  type        = string
}
variable "network" {
  description = "已存在的 VPC、Subnet、安全组和可用区。"
  type = object({
    vpc_id            = string
    subnet_id         = string
    security_group_id = string
    zone_id           = string
  })
}
variable "ecs_iam_role" {
  description = "已有 ECS Role，允许访问指定 TOS 数据湖、日志和脚本路径。"
  type        = string
}
variable "ecs_key_pair_name" {
  description = "已存在的 ECS 密钥对名称。"
  type        = string
}
variable "master_instance_type" {
  description = "Master 节点 ECS 规格。"
  type        = string
}
variable "worker_instance_type" {
  description = "Core/Task 节点 ECS 规格。"
  type        = string
}
variable "disk_type" {
  description = "目标可用区支持的 EMR 磁盘类型，按官方文档填写。"
  type        = string
}
variable "tos_bucket_name" {
  description = "已存在的私有 TOS Bucket 名称，调用方负责数据、权限、日志保留和清理。"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.tos_bucket_name))
    error_message = "填写有效 TOS Bucket 名称，不包含 tos:// 前缀。"
  }
}
variable "bootstrap_script_path" {
  description = "已上传的实际 Bootstrap 脚本 tos://bucket/key 路径；模块不上传脚本。"
  type        = string
}
variable "task_node_count" {
  description = "批处理 TASK 节点手动期望容量，不是自动伸缩策略。"
  type        = number
  default     = 2
}
variable "tags" {
  description = "集群标签。"
  type        = map(string)
  default     = { scenario = "spark-hive-data-lake" }
}
