output "cluster_id" {
  description = "EMR 集群 ID。"
  value       = volcenginecc_emr_cluster.this.cluster_id
}

output "cluster_state" {
  description = "Provider 回读的集群状态。"
  value       = volcenginecc_emr_cluster.this.cluster_state
}

output "applications" {
  description = "Provider 回读的已安装组件信息，包含实际组件版本。"
  value       = volcenginecc_emr_cluster.this.applications
}

output "task_node_group_ids" {
  description = "保留调用方逻辑 key 的 TASK 节点组 ID 映射。"
  value       = { for key, group in volcenginecc_emr_node_group.task : key => group.node_group_id }
}

output "network" {
  description = "供下游组合使用的外部网络引用；模块不管理这些依赖。"
  value       = var.network
}
