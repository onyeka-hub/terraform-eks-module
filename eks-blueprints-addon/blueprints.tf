module "eks_blueprints_addon" {
  source = "aws-ia/eks-blueprints-addon/aws"
  version = "~> 1.0" #ensure to update this to the latest/desired version

  chart            = "karpenter"
  chart_version    = "0.16.2"
  repository       = "https://charts.karpenter.sh/"
  description      = "Kubernetes Node Autoscaling: built for flexibility, performance, and simplicity"
  namespace        = "karpenter"
  create_namespace = true

  set = [
    {
      name  = "clusterName"
      value = "eks-blueprints-addon-example"
    },
    {
      name  = "clusterEndpoint"
      value = "https://EXAMPLED539D4633E53DE1B71EXAMPLE.gr7.us-west-2.eks.amazonaws.com"
    },
    {
      name  = "aws.defaultInstanceProfile"
      value = "arn:aws:iam::111111111111:instance-profile/KarpenterNodeInstanceProfile-complete"
    }
  ]

  set_irsa_names = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  # # Equivalent to the following but the ARN is only known internally to the module
  # set = [{
  #   name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
  #   value = iam_role_arn.this[0].arn
  # }]

  # IAM role for service account (IRSA)
  create_role = true
  role_name   = "karpenter-controller"
  role_policies = {
    karpenter = "arn:aws:iam::111111111111:policy/Karpenter_Controller_Policy-20221008165117447500000007"
  }

  oidc_providers = {
    this = {
      provider_arn = "oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
      # namespace is inherited from chart
      service_account = "karpenter"
    }
  }

  tags = {
    Environment = "dev"
  }
}


module "eks_blueprints" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.25.0"

  cluster_name    = "demo"
  cluster_version = "1.25"
  enable_irsa     = true

  map_roles = [
    {
      rolearn  = module.karpenter.role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },
    {
      rolearn  = aws_iam_role.developer.arn
      username = "developer"
      groups   = ["reader"]
    },
  ]

  fargate_profiles = {
    staging = {
      fargate_profile_name = "staging"
      # subnet_ids = [
      #   aws_subnet.private_us_east_1a.id,
      #   aws_subnet.private_us_east_1b.id
      # ]
      subnet_ids = module.vpc.private_subnets
      fargate_profile_namespaces = [
        { namespace = "staging" }
      ]
    }
  }

  # vpc_id = aws_vpc.main.id
  vpc_id = module.vpc.vpc_id

  # private_subnet_ids = [
  #   aws_subnet.private_us_east_1a.id,
  #   aws_subnet.private_us_east_1b.id
  # ]
  private_subnet_ids = module.vpc.private_subnets

  managed_node_groups = {
    role = {
      capacity_type   = "ON_DEMAND"
      node_group_name = "general"
      instance_types  = ["t3a.xlarge"]
      desired_size    = "1"
      max_size        = "5"
      min_size        = "1"
    }
  }
}

provider "kubernetes" {
  host                   = module.eks_blueprints.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_blueprints.eks_cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks_blueprints.eks_cluster_id]
  }
}