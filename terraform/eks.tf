# EKS Cluster and Node Group configuration

# Security group for EKS cluster
resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-cluster-sg"
    }
  )
}

# Optional: Add ingress rules for cluster security group
resource "aws_security_group_rule" "cluster_ingress_workstation_https" {
  count = var.allowed_cidr_blocks != null ? 1 : 0

  description       = "Allow workstation to communicate with the cluster API Server"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.cluster.id
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }

  # Enable control plane logging
  enabled_cluster_log_types = var.cluster_enabled_log_types

  # Encryption config
  dynamic "encryption_config" {
    for_each = var.cluster_encryption_config_enabled ? [1] : []
    content {
      provider {
        key_arn = var.cluster_encryption_config_kms_key_id
      }
      resources = ["secrets"]
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.cluster_vpc_policy,
  ]
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = aws_subnet.private[*].id

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  instance_types = var.node_instance_types
  capacity_type  = var.node_group_capacity_type
  disk_size      = var.node_group_disk_size

  update_config {
    max_unavailable = var.node_group_max_unavailable
  }

  labels = merge(
    var.node_group_labels,
    {
      role = "worker"
    }
  )

  # Add taints if specified
  dynamic "taint" {
    for_each = var.node_group_taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-node-group"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.node_group_worker,
    aws_iam_role_policy_attachment.node_group_cni,
    aws_iam_role_policy_attachment.node_group_registry,
  ]

  # Ignore changes to desired size (let autoscaling handle it)
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# EBS CSI Driver addon
resource "aws_eks_addon" "ebs_csi" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.ebs_csi_driver_version
  service_account_role_arn = aws_iam_role.ebs_csi.arn

  tags = var.tags

  depends_on = [aws_eks_node_group.main]
}

# CoreDNS addon
resource "aws_eks_addon" "coredns" {
  count = var.enable_coredns_addon ? 1 : 0

  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "coredns"
  addon_version = var.coredns_addon_version

  tags = var.tags

  depends_on = [aws_eks_node_group.main]
}

# kube-proxy addon
resource "aws_eks_addon" "kube_proxy" {
  count = var.enable_kube_proxy_addon ? 1 : 0

  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "kube-proxy"
  addon_version = var.kube_proxy_addon_version

  tags = var.tags

  depends_on = [aws_eks_node_group.main]
}

# VPC CNI addon
resource "aws_eks_addon" "vpc_cni" {
  count = var.enable_vpc_cni_addon ? 1 : 0

  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "vpc-cni"
  addon_version = var.vpc_cni_addon_version

  tags = var.tags

  depends_on = [aws_eks_node_group.main]
}
