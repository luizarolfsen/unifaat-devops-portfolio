# ============================================================
# Trust Policy — permite EC2 assumir o role
# ============================================================
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "AllowEC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# ============================================================
# IAM Role — SEURA-technova-ec2-role
# Usado por instâncias EC2 para acessar S3 sem credenciais estáticas
# ============================================================
resource "aws_iam_role" "ec2_role" {
  name               = "6325257-technova-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  description        = "Role assumida por instâncias EC2 para acesso ao S3 TechNova"

  tags = local.common_tags
}

# ============================================================
# Permissions Policy inline — S3 read/write em technova-app-data-*
# ============================================================
resource "aws_iam_role_policy" "ec2_s3_access" {
  name = "6325257-technova-ec2-s3-access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowListBucket"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::technova-app-data-*"
        ]
      },
      {
        Sid    = "AllowReadWrite"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::technova-app-data-*/*"
        ]
      }
    ]
  })
}

# ============================================================
# Instance Profile — SEURA-technova-ec2-profile
# Necessário para associar o role a instâncias EC2
# ============================================================
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "6325257-technova-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = local.common_tags
}
