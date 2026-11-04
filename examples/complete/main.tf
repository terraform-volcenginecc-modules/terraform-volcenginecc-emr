provider "volcenginecc" {
  region = var.region
}

module "emr" {
  source = "terraform-volcenginecc-modules/emr/volcenginecc"

  cluster_name        = var.cluster_name
  release_version     = var.release_version
  network             = var.network
  ecs_iam_role        = var.ecs_iam_role
  ecs_key_pair_name   = var.ecs_key_pair_name
  application_names   = ["HDFS", "YARN", "SPARK3", "HIVE"]
  history_server_mode = "LOCAL"
  tags                = var.tags
  initial_node_groups = {
    master = {
      name          = "MasterGroup"
      type          = "MASTER"
      instance_type = var.master_instance_type
      node_count    = 1
      system_disk   = { size = 120, volume_type = var.disk_type }
      data_disk     = { size = 80, volume_type = var.disk_type, count = 1 }
    }
    core = {
      name          = "CoreGroup"
      type          = "CORE"
      instance_type = var.worker_instance_type
      node_count    = 2
      system_disk   = { size = 120, volume_type = var.disk_type }
      data_disk     = { size = 200, volume_type = var.disk_type, count = 4 }
    }
  }
  task_node_groups = {
    batch = {
      name          = "BatchWorkers"
      instance_type = var.worker_instance_type
      node_count    = var.task_node_count
      system_disk   = { size = 120, volume_type = var.disk_type }
      data_disk     = { size = 200, volume_type = var.disk_type, count = 1 }
    }
  }
  bootstrap_scripts = {
    prepare = {
      script_name = "PrepareDataLake"
      script_path = var.bootstrap_script_path
      priority    = 1
    }
  }
  application_configs = {
    hive = {
      application_name = "HIVE"
      connection_type  = "BUILT_IN_MYSQL"
      connection_id    = ""
      configs = {
        managed = {
          file  = "hive-site.xml"
          key   = "hive.metastore.warehouse.dir"
          value = "tos://${var.tos_bucket_name}/warehouse/managed"
        }
        external = {
          file  = "hive-site.xml"
          key   = "hive.metastore.warehouse.external.dir"
          value = "tos://${var.tos_bucket_name}/warehouse/external"
        }
      }
    }
    spark = {
      application_name = "SPARK3"
      configs = {
        event_log_enabled = {
          file  = "spark-defaults.conf"
          key   = "spark.eventLog.enabled"
          value = "true"
        }
        event_log_directory = {
          file  = "spark-defaults.conf"
          key   = "spark.eventLog.dir"
          value = "tos://${var.tos_bucket_name}/logs/spark-events"
        }
        history_directory = {
          file  = "spark-defaults.conf"
          key   = "spark.history.fs.logDirectory"
          value = "tos://${var.tos_bucket_name}/logs/spark-events"
        }
      }
    }
  }
}
