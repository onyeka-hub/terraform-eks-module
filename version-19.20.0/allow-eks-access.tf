# # allow-eks-access IAM policy
# module "allow_eks_access_iam_policy" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
#   version = "5.3.1"

#   name          = "allow-eks-access"
#   create_policy = true

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "eks:DescribeCluster",
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       },
#     ]
#   })
# }

# # the IAM role that we will use to access the cluster. Let's call it eks-admin
# module "eks_admins_iam_role" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
#   version = "5.3.1"

#   role_name         = "eks-admin"
#   create_role       = true
#   role_requires_mfa = false

#   custom_role_policy_arns = [module.allow_eks_access_iam_policy.arn]

#   trusted_role_arns = [
#     "arn:aws:iam::${module.vpc.vpc_owner_id}:root"
#   ]
# }

# # The IAM role is ready, now let's create a test IAM user that gets access to that role.
# # Let's call it eks-user and disable creating access keys and login profiles.
# # We will generate those from the UI.

# module "eks-user_iam_user" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-user"
#   version = "5.3.1"

#   name                          = "eks-user"
#   create_iam_access_key         = false
#   create_iam_user_login_profile = false

#   force_destroy = true
# }

# # Then IAM policy to allow assume eks-admin IAM role.

# module "allow_assume_eks_admins_iam_policy" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
#   version = "5.3.1"

#   name          = "allow-assume-eks-admin-iam-role"
#   create_policy = true

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "sts:AssumeRole",
#         ]
#         Effect   = "Allow"
#         Resource = module.eks_admins_iam_role.iam_role_arn
#       },
#     ]
#   })
# }

# # Finally, we need to create an IAM group with the previous policy and put our eks-user
# # in this group.

# module "eks_admins_iam_group" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
#   version = "5.3.1"

#   name                              = "eks-admin"
#   attach_iam_self_management_policy = false
#   create_group                      = true
#   group_users                       = [module.eks-user_iam_user.iam_user_name]
#   custom_group_policy_arns          = [module.allow_assume_eks_admins_iam_policy.arn]
# }
