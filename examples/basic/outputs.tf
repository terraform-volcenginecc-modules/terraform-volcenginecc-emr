output "cluster_id" {
  description = "创建的 EMR 集群 ID。"
  value       = module.emr.cluster_id
}
output "applications" {
  description = "实际安装的组件和版本。"
  value       = module.emr.applications
}
