variable "cluster_name" {
  description = "EMR 集群名称。"
  type        = string
  validation {
    condition     = length(trimspace(var.cluster_name)) > 0
    error_message = "cluster_name 不得为空。"
  }
}

variable "release_version" {
  description = "地域内可用的 EMR 发行版本；组件版本由发行版本决定，修改可能重建集群。"
  type        = string
  validation {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+$", var.release_version))
    error_message = "release_version 必须为 x.y.z 格式。"
  }
}

variable "cluster_type" {
  description = "EMR 集群类型；具体可用类型由地域和发行版本决定。"
  type        = string
  default     = "Hadoop"
  validation {
    condition     = length(trimspace(var.cluster_type)) > 0
    error_message = "cluster_type 不得为空。"
  }
}

variable "application_names" {
  description = "安装组件名称集合；名称及组合须匹配发行版本，不能单独指定组件版本。"
  type        = set(string)
  default     = ["HDFS", "YARN", "SPARK3"]
  validation {
    condition     = length(var.application_names) > 0 && alltrue([for name in var.application_names : length(trimspace(name)) > 0])
    error_message = "至少指定一个非空组件名称。"
  }
}

variable "project_name" {
  description = "资源所属项目。"
  type        = string
  default     = "default"
  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]{1,64}$", var.project_name))
    error_message = "项目名只允许字母、数字、下划线、点和连字符，长度 1–64。"
  }
}

variable "network" {
  description = "调用方管理的 VPC、同一可用区内 Subnet 和安全组；所有节点组使用同一子网。"
  type = object({
    vpc_id            = string
    subnet_id         = string
    security_group_id = string
    zone_id           = string
  })
  validation {
    condition     = alltrue([for value in values(var.network) : length(trimspace(value)) > 0])
    error_message = "network 的四个字段均不得为空。"
  }
}

variable "ecs_iam_role" {
  description = "已存在的 ECS IAM Role 名称，调用方负责授予 EMR 所需权限和指定 TOS 路径的访问权限。"
  type        = string
  validation {
    condition     = length(trimspace(var.ecs_iam_role)) > 0
    error_message = "ecs_iam_role 不得为空。"
  }
}

variable "ecs_key_pair_name" {
  description = "已存在的 ECS SSH 密钥对名称；模块不接收明文节点密码。"
  type        = string
  validation {
    condition     = length(trimspace(var.ecs_key_pair_name)) > 0
    error_message = "ecs_key_pair_name 不得为空。"
  }
}

variable "deploy_mode" {
  description = "部署模式 SIMPLE 或 HIGH_AVAILABLE；高可用的节点数量仍需按地域文档确认。"
  type        = string
  default     = "SIMPLE"
  validation {
    condition     = contains(["SIMPLE", "HIGH_AVAILABLE"], var.deploy_mode)
    error_message = "deploy_mode 必须为 SIMPLE 或 HIGH_AVAILABLE。"
  }
}

variable "security_mode" {
  description = "EMR 安全模式，需符合目标发行版本的官方支持范围。"
  type        = string
  default     = "SIMPLE"
  validation {
    condition     = length(trimspace(var.security_mode)) > 0
    error_message = "security_mode 不得为空。"
  }
}

variable "history_server_mode" {
  description = "History Server 模式 LOCAL 或 PHS；PHS 所需外部服务由调用方配置。"
  type        = string
  default     = "LOCAL"
  validation {
    condition     = contains(["LOCAL", "PHS"], var.history_server_mode)
    error_message = "history_server_mode 必须为 LOCAL 或 PHS。"
  }
}

variable "initial_node_groups" {
  description = "创建集群时的 Master/Core 节点组。逻辑 key 仅用于输入；整个集合为创建配置，修改可能重建集群。"
  type = map(object({
    name          = string
    type          = string
    instance_type = string
    node_count    = number
    system_disk   = object({ size = number, volume_type = string })
    data_disk     = object({ size = number, volume_type = string, count = number })
  }))
  validation {
    condition = (
      length([for group in var.initial_node_groups : group if group.type == "MASTER"]) == 1 &&
      length([for group in var.initial_node_groups : group if group.type == "CORE"]) == 1 &&
      alltrue([for group in var.initial_node_groups : contains(["MASTER", "CORE"], group.type)])
    )
    error_message = "initial_node_groups 必须恰好包含一个 MASTER 和一个 CORE 组；TASK 使用 task_node_groups。"
  }
  validation {
    condition = alltrue([for group in var.initial_node_groups :
      group.node_count >= 1 && group.node_count <= 1000 && floor(group.node_count) == group.node_count &&
      group.system_disk.size >= 60 && group.system_disk.size <= 2048 && floor(group.system_disk.size) == group.system_disk.size &&
      group.data_disk.size >= 60 && group.data_disk.size <= 2048 && floor(group.data_disk.size) == group.data_disk.size &&
      group.data_disk.count >= 1 && group.data_disk.count <= 15 && floor(group.data_disk.count) == group.data_disk.count &&
      length(trimspace(group.name)) > 0 && length(trimspace(group.instance_type)) > 0 &&
      length(trimspace(group.system_disk.volume_type)) > 0 && length(trimspace(group.data_disk.volume_type)) > 0
    ])
    error_message = "节点数量须为 1–1000 的整数，系统盘与数据盘为 60–2048 GiB 整数，数据盘 1–15 块，名称和规格不能为空。"
  }
  validation {
    condition     = length(distinct([for group in var.initial_node_groups : group.name])) == length(var.initial_node_groups)
    error_message = "初始节点组名称不得重复。"
  }
}

variable "task_node_groups" {
  description = "独立 TASK 节点组，稳定 key 对应资源地址；node_count 表示手动期望容量，非自动伸缩策略。"
  type = map(object({
    name          = string
    instance_type = string
    node_count    = number
    system_disk   = object({ size = number, volume_type = string })
    data_disk     = object({ size = number, volume_type = string, count = number })
  }))
  default = {}
  validation {
    condition = alltrue([for group in var.task_node_groups :
      group.node_count >= 1 && group.node_count <= 1000 && floor(group.node_count) == group.node_count &&
      group.system_disk.size >= 60 && group.system_disk.size <= 2048 && floor(group.system_disk.size) == group.system_disk.size &&
      group.data_disk.size >= 60 && group.data_disk.size <= 2048 && floor(group.data_disk.size) == group.data_disk.size &&
      group.data_disk.count >= 1 && group.data_disk.count <= 15 && floor(group.data_disk.count) == group.data_disk.count &&
      length(trimspace(group.name)) > 0 && length(trimspace(group.instance_type)) > 0 &&
      length(trimspace(group.system_disk.volume_type)) > 0 && length(trimspace(group.data_disk.volume_type)) > 0
    ])
    error_message = "TASK 节点数量、磁盘容量和名称必须符合初始节点组相同的约束。"
  }
}

variable "bootstrap_scripts" {
  description = "TOS 中已存在的 Bootstrap 脚本；按 priority 执行，作用于整个集群，改变配置可能重建集群。"
  type = map(object({
    script_name             = string
    script_path             = string
    script_args             = optional(string, "")
    priority                = optional(number, 1)
    execution_moment        = optional(string, "BEFORE_APPLICATION_INSTALL")
    execution_fail_strategy = optional(string, "FAILED_BLOCK")
  }))
  default = {}
  validation {
    condition = alltrue([for script in var.bootstrap_scripts :
      can(regex("^tos://[^/]+/.+", script.script_path)) &&
      length(trimspace(script.script_name)) > 0 && length(script.script_name) <= 128 &&
      script.priority >= 1 && script.priority <= 1000 && floor(script.priority) == script.priority &&
      contains(["BEFORE_APPLICATION_INSTALL", "AFTER_APPLICATION_STARTED"], script.execution_moment) &&
      contains(["FAILED_CONTINUE", "FAILED_BLOCK"], script.execution_fail_strategy)
    ])
    error_message = "Bootstrap 需要有效 tos://bucket/key 路径、名称、整数 priority (1–1000) 和支持的执行/失败策略。"
  }
}

variable "application_configs" {
  description = "组件配置，作用于整个集群；可配置 Hive TOS 仓库和 Spark 事件日志。发行版本决定配置项是否生效，禁止包含凭证。"
  type = map(object({
    application_name = string
    connection_type  = optional(string)
    connection_id    = optional(string)
    configs = map(object({
      file  = string
      key   = string
      value = string
    }))
  }))
  default = {}
  validation {
    condition = alltrue([for app in var.application_configs :
      length(trimspace(app.application_name)) > 0 &&
      (app.connection_type == null ? app.connection_id == null : contains(["BUILT_IN_MYSQL", "EXTERNAL_MYSQL", "HIVE_METASTORE"], app.connection_type)) &&
      alltrue([for config in app.configs : length(trimspace(config.file)) > 0 && length(trimspace(config.key)) > 0])
    ])
    error_message = "组件名称、配置文件和配置键不得为空；连接类型必须受支持，connection_id 不能单独设置。"
  }
  validation {
    condition = alltrue([for app in var.application_configs :
      app.connection_type == null || app.connection_type == "BUILT_IN_MYSQL" ? true :
      (app.connection_id == null ? false : length(trimspace(app.connection_id)) > 0)
    ])
    error_message = "外部元数据连接必须提供非空 connection_id。"
  }
  validation {
    condition = alltrue([for app in var.application_configs :
      length(distinct([for config in app.configs : jsonencode([config.file, config.key])])) == length(app.configs)
    ])
    error_message = "同一组件中配置文件和配置键的组合不得重复。"
  }
  validation {
    condition     = length(distinct([for app in var.application_configs : app.application_name])) == length(var.application_configs)
    error_message = "同一组件必须集中在一个 application_configs 对象内。"
  }
}

variable "tags" {
  description = "集群标签；null 表示未配置，显式空 map 表示清空标签；不隐式应用于外部依赖。"
  type        = map(string)
  default     = null
  validation {
    condition     = var.tags == null ? true : alltrue([for key in keys(var.tags) : length(trimspace(key)) > 0])
    error_message = "标签 key 不得为空。"
  }
}
