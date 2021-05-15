locals {
  is_replication_master    = length(var.replications) > 0
  is_replication_mode      = var.replication_slave || local.is_replication_master
  replication_master_count = local.is_replication_master ? 1 : 0
}