output "cluster_name" {
  value = aws_eks_cluster.eks-cluster.name
}

output "alb_role_arn" {
  value = aws_iam_role.alb_controller_role.arn
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}