# ============================================================
# locals — tag set reutilizável em todos os recursos
# ============================================================
locals {
  common_tags = {
    Project    = var.project_name
    ManagedBy  = "Terraform"
    Aluno      = "Luiza Carneiro Rolfsen"
    RA         = "6325257"
    Disciplina = "DevOps - UniFAAT 2026-2"
    Aula       = "03"
  }
}

# ============================================================
# IAM Groups
# ============================================================
resource "aws_iam_group" "developers" {
  name = "6325257-technova-developers"
}

resource "aws_iam_group" "platform_eng" {
  name = "6325257-technova-platform-eng"
}

# ============================================================
# IAM Users
# ============================================================
resource "aws_iam_user" "juliana_dev" {
  name = "6325257-juliana-dev"
  tags = local.common_tags
}

resource "aws_iam_user" "rafael_platform" {
  name = "6325257-rafael-platform"
  tags = local.common_tags
}

resource "aws_iam_user" "lucas_intern" {
  name = "6325257-lucas-intern"
  tags = local.common_tags
}

# ============================================================
# Group Memberships
# developers: juliana + rafael + lucas
# platform-eng: rafael (somente)
# ============================================================
resource "aws_iam_group_membership" "developers_membership" {
  name  = "6325257-technova-developers-membership"
  group = aws_iam_group.developers.name

  users = [
    aws_iam_user.juliana_dev.name,
    aws_iam_user.rafael_platform.name,
    aws_iam_user.lucas_intern.name,
  ]
}

resource "aws_iam_group_membership" "platform_eng_membership" {
  name  = "6325257-technova-platform-eng-membership"
  group = aws_iam_group.platform_eng.name

  users = [
    aws_iam_user.rafael_platform.name,
  ]
}
