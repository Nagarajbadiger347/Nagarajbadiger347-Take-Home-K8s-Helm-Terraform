# Terraform Infrastructure

This folder has everything you need to spin up an EKS cluster on AWS. The configuration is split into separate files to keep things organized and easy to work with.

## What's Inside

```
terraform/
├── main.tf              # Provider setup
├── variables.tf         # All configurable variables
├── outputs.tf           # Useful outputs after deployment
├── vpc.tf              # Network setup (VPC, subnets, NAT gateways)
├── iam.tf              # Permissions for cluster and nodes
├── eks.tf              # The actual EKS cluster and worker nodes
├── backend.tf.example  # Template for remote state storage
└── environments/       # Different configs for different environments
    ├── dev.tfvars      # Dev environment settings
    ├── prod.tfvars     # Production environment settings
    └── ci.tfvars       # CI/testing environment settings
```

## Getting Started

The easiest way to get going is to use one of the environment configs. Here's how to deploy a dev environment:

```bash
cd terraform

# First time setup
terraform init

# See what will be created
terraform plan -var-file="environments/dev.tfvars"

# Create it
terraform apply -var-file="environments/dev.tfvars"

# Check the outputs
terraform output
```

For production or CI environments, just swap out the tfvars file:

```bash
terraform apply -var-file="environments/prod.tfvars"
# or
terraform apply -var-file="environments/ci.tfvars"
```

## Configuring Variables

All the variables have reasonable defaults set in `variables.tf`, but you'll probably want to customize some things. There are a few ways to do this:

1. Use the environment-specific tfvars files (easiest and recommended)
2. Create a `terraform.tfvars` file for shared settings
3. Pass them on the command line: `-var="cluster_name=my-cluster"`
4. Set environment variables: `TF_VAR_cluster_name=my-cluster`

### Important Variables to Know

**General stuff:**
- `aws_region` - Where to deploy (defaults to us-west-2)
- `cluster_name` - What to call your cluster
- `tags` - Tags that get applied to everything

**Network settings:**
- `vpc_cidr` - Your VPC's IP range
- `availability_zones_count` - How many AZs to spread across
- `single_nat_gateway` - Set to true to save money in dev (uses one NAT gateway instead of one per AZ)

**Cluster configuration:**
- `kubernetes_version` - Which K8s version to run
- `cluster_endpoint_private_access` - Allow private VPC access
- `cluster_endpoint_public_access` - Allow public internet access
- `cluster_enabled_log_types` - What to log from the control plane

**Worker nodes:**
- `node_instance_types` - EC2 instance types (like t3.medium)
- `node_group_desired_size` - How many nodes you want
- `node_group_min_size` - Minimum nodes for autoscaling
- `node_group_max_size` - Maximum nodes for autoscaling
- `node_group_capacity_type` - Use ON_DEMAND or SPOT instances
- `node_group_disk_size` - Disk size for each node

**EKS addons:**
- `enable_ebs_csi_driver` - You need this for persistent volumes (enabled by default)
- `enable_coredns_addon` - Usually don't need this, CoreDNS comes pre-installed
- `enable_kube_proxy_addon` - Same deal, comes with the cluster
- `enable_vpc_cni_addon` - Also pre-installed

## Environment Configs Explained

We've set up three different configs that you can use depending on what you're doing:

**Dev environment** - Cheap and cheerful for development work:
- 2 availability zones with a single NAT gateway
- t3.medium instances (2 vCPU, 4GB RAM)
- 1-3 nodes depending on load
- Basic logging to save costs
- Single NAT saves about $30/month

**Production** - High availability, no compromises:
- 3 availability zones, each with its own NAT gateway
- t3.large instances (2 vCPU, 8GB RAM)
- 2-10 nodes with autoscaling
- Full logging enabled
- Multi-AZ NAT for redundancy

**CI/Testing** - Bare minimum for running tests:
- 2 availability zones, single NAT
- t3.small instances (cheap!)
- 1-2 nodes using SPOT instances (even cheaper!)
- Minimal logging
- Perfect for automated testing that gets torn down after

## Making Your Own Environment

Want a staging environment or something else? Just copy one of the existing configs:

```bash
cp environments/dev.tfvars environments/staging.tfvars
```

Then edit it with your preferences:

```hcl
cluster_name = "demo-eks-staging"
node_instance_types = ["t3.medium"]
node_group_desired_size = 2
# whatever else you need
```

Deploy it:

```bash
terraform apply -var-file="environments/staging.tfvars"
```

## Common Customizations

**Want to save money in dev/test?** Use SPOT instances:

```hcl
node_group_capacity_type = "SPOT"
```

**Need encryption at rest?** First create a KMS key, then:

```hcl
cluster_encryption_config_enabled = true
cluster_encryption_config_kms_key_id = "arn:aws:kms:your-region:account:key/xyz"
```

**Lock down API access?** Restrict who can talk to your cluster:

```hcl
cluster_endpoint_public_access_cidrs = ["1.2.3.4/32", "5.6.7.8/32"]
```

## Getting Info After Deployment

Once everything's deployed, you can grab useful info with:

```bash
# See everything
terraform output

# Get specific values
terraform output cluster_endpoint
terraform output configure_kubectl

# Get it as JSON if you need to parse it
terraform output -json
```

You'll get stuff like:
- Cluster name and endpoint
- The kubectl config command (copy/paste this to connect)
- VPC and subnet IDs
- Security group IDs

## Setting Up Remote State (Important for Teams!)

If you're working with a team or want to keep your state safe, you should use remote state in S3. Here's how:

First, create the S3 bucket and DynamoDB table for locking:

```bash
aws s3 mb s3://my-terraform-state-bucket

aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

Then copy and edit the backend config:

```bash
cp backend.tf.example backend.tf
# Edit backend.tf and put in your actual bucket name
```

Re-initialize Terraform to use the backend:

```bash
terraform init -backend-config="backend.tf"
```

This keeps your state in S3 and prevents multiple people from making changes at the same time.

## Cost Optimization

### Development
- Use `single_nat_gateway = true` (saves ~$32/month per NAT)
- Use smaller instances
- Use SPOT instances
- Reduce node count

### Production
- Use `single_nat_gateway = false` for HA
- Use ON_DEMAND instances
- Configure autoscaling properly
- Use Reserved Instances for stable workloads

## Common Operations

### Update Kubernetes Version

```hcl
# In tfvars
kubernetes_version = "1.29"
```

```bash
terraform apply -var-file="environments/dev.tfvars"
```

### Scale Node Group

```hcl
node_group_desired_size = 5
```

Or via kubectl/AWS Console (Terraform will reconcile on next apply)

### Add Node Labels

```hcl
node_group_labels = {
  workload_type = "compute"
  team          = "platform"
}
```

### Add Node Taints

```hcl
node_group_taints = [
  {
    key    = "dedicated"
    value  = "gpu"
    effect = "NoSchedule"
  }
]
```

## Troubleshooting

### Cannot connect to cluster

```bash
# Update kubeconfig
aws eks update-kubeconfig --name demo-eks-dev --region us-west-2

# Test connection
kubectl get nodes
```

### Nodes not joining cluster

Check IAM roles have required policies attached.

### EBS CSI driver issues

Ensure OIDC provider is configured and EBS CSI IAM role is created.

## Clean Up

```bash
# Destroy infrastructure
terraform destroy -var-file="environments/dev.tfvars"

# Or target specific resources
terraform destroy -target=aws_eks_node_group.main
```

## Module Structure

This is a flat configuration (no modules) for simplicity and learning. For production, consider:

- Breaking into reusable modules
- Using Terraform Cloud/Enterprise
- Implementing proper state locking
- Setting up automated testing

## References

- [AWS EKS Terraform Guide](https://learn.hashicorp.com/tutorials/terraform/eks)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
