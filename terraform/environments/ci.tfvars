# CI/Testing environment configuration
# Minimal resources for automated testing

cluster_name       = "demo-eks-ci"
aws_region         = "us-west-2"
kubernetes_version = "1.28"

# Tags
tags = {
  Project     = "eks-demo"
  Environment = "ci"
  ManagedBy   = "terraform"
  AutoDelete  = "yes"
}

# Network - minimal
vpc_cidr                = "10.0.0.0/16"
availability_zones_count = 2
single_nat_gateway      = true

# Cluster access
cluster_endpoint_private_access      = true
cluster_endpoint_public_access       = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

# Minimal logging
cluster_enabled_log_types = ["api"]

# Small node group
node_instance_types       = ["t3.small"]
node_group_desired_size   = 1
node_group_min_size       = 1
node_group_max_size       = 2
node_group_capacity_type  = "SPOT" # Cost savings
node_group_disk_size      = 30

# EKS addons
enable_ebs_csi_driver     = true
enable_coredns_addon      = false
enable_kube_proxy_addon   = false
enable_vpc_cni_addon      = false
