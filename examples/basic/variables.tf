variable "region" {
  description = "部署地域。"
  type        = string
}
variable "cluster_name" {
  description = "集群名称。"
  type        = string
}
variable "release_version" {
  description = "该地域可用的 EMR 发行版本。"
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
  description = "已配置 EMR 权限的 ECS Role 名称。"
  type        = string
}
variable "ecs_key_pair_name" {
  description = "已存在的 ECS 密钥对名称。"
  type        = string
}
variable "instance_type" {
  description = "可用区内 EMR 支持的 ECS 规格。"
  type        = string
}
variable "disk_type" {
  description = "目标可用区支持的 EMR 磁盘类型，按官方文档填写。"
  type        = string
}
