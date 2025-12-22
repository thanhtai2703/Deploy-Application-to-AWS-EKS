resource "aws_eks_cluster" "eks-cluster" {
  name     = var.cluster-name
  role_arn = aws_iam_role.EKSClusterRole.arn
  vpc_config {
    subnet_ids         = [
      aws_subnet.public-subnet.id, 
      aws_subnet.public-subnet2.id,
      aws_subnet.private-subnet.id,
      aws_subnet.private-subnet2.id
    ]
    security_group_ids = [aws_security_group.sg-default.id]
  }

  version = 1.32

  depends_on = [aws_iam_role_policy_attachment.AmazonEKSClusterPolicy]
}

# --- OIDC Provider for IRSA ---
data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks-cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks-cluster.identity[0].oidc[0].issuer
}

# --- Updated: Install EBS CSI Driver with IRSA ---
resource "aws_eks_addon" "ebs-csi" {
  cluster_name             = aws_eks_cluster.eks-cluster.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.39.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  
  # Link to the IAM Role created in iam-role.tf
  service_account_role_arn = aws_iam_role.ebs_csi_role.arn

  depends_on = [
    aws_eks_node_group.eks-node-group
  ]
}

# --- DIAGNOSTIC: Allow ALL traffic to Nodes ---

resource "aws_security_group_rule" "allow_all_diagnostic" {

  type              = "ingress"

  from_port         = 0

  to_port           = 65535

  protocol          = "tcp"

  cidr_blocks       = ["0.0.0.0/0"]

  security_group_id = aws_eks_cluster.eks-cluster.vpc_config[0].cluster_security_group_id

  description       = "TEMPORARY: Allow all for diagnostics"

}
