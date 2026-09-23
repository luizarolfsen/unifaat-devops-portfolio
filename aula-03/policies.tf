# ============================================================
# Policy 1 — S3 Read (developers)
# Permite ListBucket + GetObject em buckets technova-*
# ============================================================
resource "aws_iam_policy" "s3_read" {
  name        = "6325257-technova-s3-read"
  description = "Permite leitura em buckets S3 com prefixo technova-* para o grupo developers"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowListBucket"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::technova-*"
        ]
      },
      {
        Sid    = "AllowGetObject"
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = [
          "arn:aws:s3:::technova-*/*"
        ]
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_group_policy_attachment" "developers_s3_read" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.s3_read.arn
}

# ============================================================
# Policy 2 — EC2 + S3 Full (platform-eng)
# EC2: Describe* (sem restrição) + Start/Stop com condition tag
# S3: ListBucket + GetObject + PutObject em technova-*
# ============================================================
resource "aws_iam_policy" "ec2_s3_full" {
  name        = "6325257-technova-ec2-s3-full"
  description = "Acesso completo EC2 (com condition tag) e S3 read/write em technova-* para platform-eng"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowEC2Describe"
        Effect   = "Allow"
        Action   = ["ec2:Describe*"]
        Resource = ["*"]
      },
      {
        Sid    = "AllowEC2StartStopWithTag"
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = ["*"]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Project" = "TechNova"
          }
        }
      },
      {
        Sid    = "AllowS3ListBucket"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::technova-*"
        ]
      },
      {
        Sid    = "AllowS3ReadWrite"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::technova-*/*"
        ]
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_group_policy_attachment" "platform_eng_ec2_s3_full" {
  group      = aws_iam_group.platform_eng.name
  policy_arn = aws_iam_policy.ec2_s3_full.arn
}

# ============================================================
# Policy 3 — Deny Destructive (developers)
# Nega explicitamente qualquer ação Delete* ou Terminate*
# Proteção extra para evitar deleção acidental de recursos
# ============================================================
resource "aws_iam_policy" "deny_destructive" {
  name        = "6325257-technova-deny-destructive"
  description = "Nega explicitamente ações Delete* e Terminate* em todos os recursos para o grupo developers"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyDestructiveActions"
        Effect = "Deny"
        Action = [
          "Delete*",
          "Terminate*"
        ]
        Resource = ["*"]
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_group_policy_attachment" "developers_deny_destructive" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.deny_destructive.arn
}
