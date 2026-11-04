provider "volcenginecc" {
  region = var.region
}

module "emr" {
  source = "terraform-volcenginecc-modules/emr/volcenginecc"

  cluster_name      = var.cluster_name
  release_version   = var.release_version
  network           = var.network
  ecs_iam_role      = var.ecs_iam_role
  ecs_key_pair_name = var.ecs_key_pair_name
  application_names = ["HDFS", "YARN", "SPARK3"]
  initial_node_groups = {
    master = {
      name          = "MasterGroup"
      type          = "MASTER"
      instance_type = var.instance_type
      node_count    = 1
      system_disk   = { size = 120, volume_type = var.disk_type }
      data_disk     = { size = 80, volume_type = var.disk_type, count = 1 }
    }
    core = {
      name          = "CoreGroup"
      type          = "CORE"
      instance_type = var.instance_type
      node_count    = 2
      system_disk   = { size = 120, volume_type = var.disk_type }
      data_disk     = { size = 80, volume_type = var.disk_type, count = 4 }
    }
  }
}
