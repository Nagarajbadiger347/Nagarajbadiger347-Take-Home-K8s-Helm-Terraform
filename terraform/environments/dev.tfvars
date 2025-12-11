# Development environment configuration
# Cost-optimized setup for dev/test

cluster_name       = "demo-eks-dev"
aws_region         = "us-west-2"
kubernetes_version = "1.28"

# Tags
tags = {
  Project     = "eks-demo"
  Environment = "development"
  ManagedBy   = "terraform"
  CostCenter  = "engineering"
}

# Network - smaller for dev
vpc_cidr                = "10.0.0.0/16"
availability_zones_count = 2
single_nat_gateway      = true # Cost savings - single NAT instead of per-AZ

# Cluster access
cluster_endpoint_private_access      = true
cluster_endpoint_public_access       = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

# Logging - minimal for dev
cluster_enabled_log_types = ["api", "audit"]

# Node group - smaller instances
node_instance_types       = ["t3.medium"]
node_group_desired_size   = 2
node_group_min_size       = 1
node_group_max_size       = 3
node_group_capacity_type  = "ON_DEMAND"
node_group_disk_size      = 50

# EKS addons
enable_ebs_csi_driver     = true
enable_coredns_addon      = false # Use default
enable_kube_proxy_addon   = false # Use default
enable_vpc_cni_addon      = false # Use default
