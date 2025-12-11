# Production environment configuration
# High-availability, production-ready setup

cluster_name       = "demo-eks-prod"
aws_region         = "us-west-2"
kubernetes_version = "1.28"

# Tags
tags = {
  Project     = "eks-demo"
  Environment = "production"
  ManagedBy   = "terraform"
  CostCenter  = "operations"
  Backup      = "required"
}

# Network - multi-AZ for HA
vpc_cidr                = "10.0.0.0/16"
availability_zones_count = 3
single_nat_gateway      = false # HA - NAT per AZ

# Cluster access - more restricted
cluster_endpoint_private_access      = true
cluster_endpoint_public_access       = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # TODO: Restrict to company IPs

# Logging - all types for audit
cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

# Encryption
cluster_encryption_config_enabled = false # Enable when KMS key is ready

# Node group - larger, autoscaling
node_instance_types       = ["t3.large"]
node_group_desired_size   = 3
node_group_min_size       = 2
node_group_max_size       = 10
node_group_capacity_type  = "ON_DEMAND"
node_group_disk_size      = 100
node_group_max_unavailable = 1

# Node labels for workload placement
node_group_labels = {
  workload_type = "general"
}

# EKS addons - all enabled for prod
enable_ebs_csi_driver     = true
enable_coredns_addon      = true
enable_kube_proxy_addon   = true
enable_vpc_cni_addon      = true
