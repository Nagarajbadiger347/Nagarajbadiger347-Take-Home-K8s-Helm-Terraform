# Input variables for EKS cluster configuration
# These can be overridden via terraform.tfvars or command line

# -----------------------------------
# General Configuration
# -----------------------------------

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "demo-eks-cluster"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "eks-demo"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# -----------------------------------
# Networking Configuration
# -----------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones_count" {
  description = "Number of availability zones to use (2 or 3 recommended)"
  type        = number
  default     = 2
}

variable "subnet_cidr_bits" {
  description = "Number of bits to add when subnetting the VPC"
  type        = number
  default     = 4
}

variable "single_nat_gateway" {
  description = "Use single NAT gateway for all AZs (cost savings for dev/test)"
  type        = bool
  default     = false
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access cluster API (null = no restriction)"
  type        = list(string)
  default     = null
}

# -----------------------------------
# EKS Cluster Configuration
# -----------------------------------

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_enabled_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_encryption_config_enabled" {
  description = "Enable encryption of Kubernetes secrets using KMS"
  type        = bool
  default     = false
}

variable "cluster_encryption_config_kms_key_id" {
  description = "KMS key ID for encrypting Kubernetes secrets"
  type        = string
  default     = ""
}

# -----------------------------------
# Node Group Configuration
# -----------------------------------

variable "node_instance_types" {
  description = "Instance types for the EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "node_group_capacity_type" {
  description = "Capacity type for node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_group_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 50
}

variable "node_group_max_unavailable" {
  description = "Maximum number of nodes unavailable during updates"
  type        = number
  default     = 1
}

variable "node_group_labels" {
  description = "Key-value map of Kubernetes labels for nodes"
  type        = map(string)
  default     = {}
}

variable "node_group_taints" {
  description = "List of Kubernetes taints to apply to nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

# -----------------------------------
# EKS Addons Configuration
# -----------------------------------

variable "enable_ebs_csi_driver" {
  description = "Enable EBS CSI driver addon for persistent volumes"
  type        = bool
  default     = true
}

variable "ebs_csi_driver_version" {
  description = "Version of EBS CSI driver addon"
  type        = string
  default     = "v1.25.0-eksbuild.1"
}

variable "enable_coredns_addon" {
  description = "Enable CoreDNS addon"
  type        = bool
  default     = false
}

variable "coredns_addon_version" {
  description = "Version of CoreDNS addon"
  type        = string
  default     = "v1.10.1-eksbuild.6"
}

variable "enable_kube_proxy_addon" {
  description = "Enable kube-proxy addon"
  type        = bool
  default     = false
}

variable "kube_proxy_addon_version" {
  description = "Version of kube-proxy addon"
  type        = string
  default     = "v1.28.2-eksbuild.2"
}

variable "enable_vpc_cni_addon" {
  description = "Enable VPC CNI addon"
  type        = bool
  default     = false
}

variable "vpc_cni_addon_version" {
  description = "Version of VPC CNI addon"
  type        = string
  default     = "v1.15.1-eksbuild.1"
}
