# VPC module
# KMS module
# Kubernetes components - https://kubernetes.io/docs/concepts/overview/components/#:~:text=kube%2Dproxy%20is%20a%20network,or%20outside%20of%20your%20cluster.
# Add-ons
# coredns - https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html
# vpc-cni - https://docs.amazonaws.cn/en_us/eks/latest/userguide/cni-iam-role.html
# Node Groups & Fargate configuration 
# Taints and tolerations are a mechanism that allows you to ensure that pods are not placed on inappropriate nodes. Taints are added to nodes, while tolerations are defined in the pod specification
# For example, most Kubernetes distributions will automatically taint the master nodes so that one of the pods that manages the control plane is scheduled onto them and not any other data plane pods deployed by users
# kubectl taint nodes nodename activeEnv=green:NoSchedule
# tolerations:
# - effect: NoSchedule
#   key: activeEnv
#   operator: Equal
#   value: green
# Update kubeconfig to connect to the EKS cluster
# aws eks update-kubeconfig --name cluster-name --region us-east-2 --kubeconfig ~/.kube/config
# kubectl config get-contexts 
# kubectl config use-context arn:aws:eks:eu-west-2:832611670348:cluster/masterclass-cluster

############# Provider & Backend #############
########################################

provider "aws" {
  region = var.region
}

# ############# Data Sources #############
# ########################################
data "aws_eks_cluster" "default" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "default" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.default.token
}

############# Encryption key #############
########################################
resource "aws_kms_key" "eks_cluster_key" {
  description = "onyeka EKS Secret Encryption Key"
}


################################################################################
# vpc module: this is aws vpc module that will create a vpc with its associate resources 
#like subnets, internet and nat gateway, route tables, etc
################################################################################
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                   = var.name
  cidr                   = var.vpc_cidr
  azs                    = ["us-east-2a", "us-east-2b"]
  public_subnets         = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets        = ["10.0.3.0/24", "10.0.4.0/24"]
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  # create_igw             = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

  vpc_tags                 = var.vpc_tags
  public_route_table_tags  = var.public_route_table_tags
  private_route_table_tags = var.private_route_table_tags
  nat_gateway_tags         = var.nat_gateway_tags
  nat_eip_tags             = var.nat_eip_tags
  public_subnet_names      = var.public_subnet_names
  private_subnet_names     = var.private_subnet_names
}


################################################################################
# eks module: this is aws eks module that will create an eks with its associate resources 
################################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.24"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  cluster_encryption_config = {
    provider_key_arn = "aws_kms_key.eks_cluster_key.arn"
    resources        = ["secrets"]
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
  # control_plane_subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]

  # Self Managed Node Group(s)
  # self_managed_node_group_defaults = {
  #   instance_type                          = "m6i.large"
  #   update_launch_template_default_version = true
  #   iam_role_additional_policies = {
  #     AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  #   }
  # }

  #   self_managed_node_groups = {
  #     one = {
  #       name         = "mixed-1"
  #       max_size     = 5
  #       desired_size = 2

  #       use_mixed_instances_policy = true
  #       mixed_instances_policy = {
  #         instances_distribution = {
  #           on_demand_base_capacity                  = 0
  #           on_demand_percentage_above_base_capacity = 10
  #           spot_allocation_Onu                 = "capacity-optimized"
  #         }

  #         override = [
  #           {
  #             instance_type     = "t3.large"
  #             weighted_capacity = "1"
  #           },
  #           {
  #             instance_type     = "m6i.large"
  #             weighted_capacity = "2"
  #           },
  #         ]
  #       }
  #     }
  #   }

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t3.large", "m5n.large", "t2.medium"]
  }

  eks_managed_node_groups = {
    blue = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      use_custom_launch_template = false
      disk_size                  = 500

      instance_types = ["t2.medium"]
      capacity_type  = "SPOT"
    }
    green = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      use_custom_launch_template = false
      disk_size                  = 500

      instance_types = ["t2.medium"]
      capacity_type  = "SPOT"
    }
  }

  # Fargate Profile(s)
  # fargate_profiles = {
  #   default = {
  #     name = "default"
  #     selectors = [
  #       {
  #         namespace = "default"
  #       }
  #     ]
  #   }
  # }

  # aws-auth configmap
  manage_aws_auth_configmap = true
  # create_aws_auth_configmap = true

  # aws_auth_roles = [
  #   {
  #     rolearn  = "arn:aws:iam::958217526797:role/s3_Admin_access"
  #     username = "LambdaToS3"
  #     groups   = ["system:masters"]
  #   },
  # ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::938106001005:user/github-action-afxtern-pod-a"
      username = "github-action-afxtern-pod-a"
      groups   = ["system:masters"]
    },
    #     {
    #       userarn  = "arn:aws:iam::66666666666:user/user2"
    #       username = "user2"
    #       groups   = ["system:masters"]
    #     },
    #   ]

    #   aws_auth_accounts = [
    #     "777777777777",
    #     "888888888888",
    # ]
  ]

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

################################################################################
# Route53 resource  
################################################################################

resource "aws_route53_zone" "primary" {
  name = "onyekaonu.site"
}