locals {
  cluster_scope = {
    effective_type   = "CLUSTER"
    component_names  = []
    node_group_ids   = []
    node_group_names = []
    node_group_types = []
    node_ids         = []
    node_names       = []
  }
}

resource "volcenginecc_emr_cluster" "this" {
  cluster_name        = var.cluster_name
  cluster_type        = var.cluster_type
  release_version     = var.release_version
  application_names   = var.application_names
  project_name        = var.project_name
  charge_type         = "POST"
  deploy_mode         = var.deploy_mode
  security_mode       = var.security_mode
  history_server_mode = var.history_server_mode
  vpc_id              = var.network.vpc_id
  security_group_id   = var.network.security_group_id
  node_attribute = {
    zone_id      = var.network.zone_id
    ecs_iam_role = var.ecs_iam_role
  }
  node_group_attributes = [for key in sort(keys(var.initial_node_groups)) : {
    node_group_name    = var.initial_node_groups[key].name
    node_group_type    = var.initial_node_groups[key].type
    node_count         = var.initial_node_groups[key].node_count
    ecs_instance_types = [var.initial_node_groups[key].instance_type]
    ecs_key_pair_name  = var.ecs_key_pair_name
    ecs_password       = ""
    zone_id            = var.network.zone_id
    subnet_ids         = [var.network.subnet_id]
    charge_type        = "POST"
    with_public_ip     = false
    bandwidth          = 0
    system_disk        = var.initial_node_groups[key].system_disk
    data_disks         = [var.initial_node_groups[key].data_disk]
  }]
  bootstrap_scripts = [for key in sort(keys(var.bootstrap_scripts)) : {
    script_name             = var.bootstrap_scripts[key].script_name
    script_path             = var.bootstrap_scripts[key].script_path
    script_args             = var.bootstrap_scripts[key].script_args
    priority                = tostring(var.bootstrap_scripts[key].priority)
    script_type             = "BOOTSTRAP"
    execution_moment        = var.bootstrap_scripts[key].execution_moment
    execution_fail_strategy = var.bootstrap_scripts[key].execution_fail_strategy
    effective_scope         = local.cluster_scope
  }]
  # Omit unused optional/computed fields: Read may return null rather than [].
  application_extras = length(var.application_configs) == 0 ? null : [for key in sort(keys(var.application_configs)) : {
    application_name              = var.application_configs[key].application_name
    connection_type               = var.application_configs[key].connection_type
    connection_id                 = var.application_configs[key].connection_id
    application_component_layouts = []
    application_configs = [for config_key in sort(keys(var.application_configs[key].configs)) : {
      config_file_name        = var.application_configs[key].configs[config_key].file
      config_item_key         = var.application_configs[key].configs[config_key].key
      config_item_value       = var.application_configs[key].configs[config_key].value
      deleted                 = false
      component_instance_name = ""
      component_name          = ""
      effective_scope         = local.cluster_scope
    }]
  }]
  tags = var.tags == null ? null : [for key in sort(keys(var.tags)) : { key = key, value = var.tags[key] }]

  lifecycle {
    precondition {
      condition = length(distinct(concat(
        [for group in var.initial_node_groups : group.name],
        [for group in var.task_node_groups : group.name]
      ))) == length(var.initial_node_groups) + length(var.task_node_groups)
      error_message = "所有初始和 TASK 节点组的名称必须唯一。"
    }
    precondition {
      condition     = alltrue([for app in var.application_configs : contains(var.application_names, app.application_name)])
      error_message = "application_configs 中的组件必须包含在 application_names 中。"
    }
  }
}

resource "volcenginecc_emr_node_group" "task" {
  for_each           = var.task_node_groups
  cluster_id         = volcenginecc_emr_cluster.this.cluster_id
  node_group_name    = each.value.name
  node_group_type    = "TASK"
  charge_type        = "POST"
  node_count         = each.value.node_count
  ecs_instance_types = [each.value.instance_type]
  zone_id            = var.network.zone_id
  subnet_ids         = [var.network.subnet_id]
  with_public_ip     = false
  system_disk        = each.value.system_disk
  data_disks         = [each.value.data_disk]
}
