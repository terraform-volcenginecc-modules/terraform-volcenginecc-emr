output "cluster_id" {
  description = "EMR 集群 ID。"
  value       = module.emr.cluster_id
}
output "task_node_group_ids" {
  description = "批处理节点组逻辑 key 与 ID。"
  value       = module.emr.task_node_group_ids
}
output "applications" {
  description = "实际安装组件及版本。"
  value       = module.emr.applications
}
output "data_lake_paths" {
  description = "调用方管理的 TOS 数据和日志路径。"
  value = {
    managed_warehouse  = "tos://${var.tos_bucket_name}/warehouse/managed"
    external_warehouse = "tos://${var.tos_bucket_name}/warehouse/external"
    spark_event_logs   = "tos://${var.tos_bucket_name}/logs/spark-events"
  }
}
