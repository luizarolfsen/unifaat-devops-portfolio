# ============================================================
# Outputs — IAM Users
# ============================================================
output "user_juliana_arn" {
  description = "ARN do usuário 6325257-juliana-dev"
  value       = aws_iam_user.juliana_dev.arn
}

output "user_rafael_arn" {
  description = "ARN do usuário 6325257-rafael-platform"
  value       = aws_iam_user.rafael_platform.arn
}

output "user_lucas_arn" {
  description = "ARN do usuário 6325257-lucas-intern"
  value       = aws_iam_user.lucas_intern.arn
}

# ============================================================
# Outputs — IAM Groups
# ============================================================
output "group_developers_name" {
  description = "Nome do grupo 6325257-technova-developers"
  value       = aws_iam_group.developers.name
}

output "group_platform_eng_name" {
  description = "Nome do grupo 6325257-technova-platform-eng"
  value       = aws_iam_group.platform_eng.name
}

# ============================================================
# Outputs — Custom IAM Policies
# ============================================================
output "policy_s3_read_arn" {
  description = "ARN da policy 6325257-technova-s3-read"
  value       = aws_iam_policy.s3_read.arn
}

output "policy_ec2_s3_full_arn" {
  description = "ARN da policy 6325257-technova-ec2-s3-full"
  value       = aws_iam_policy.ec2_s3_full.arn
}

output "policy_deny_destructive_arn" {
  description = "ARN da policy 6325257-technova-deny-destructive"
  value       = aws_iam_policy.deny_destructive.arn
}

# ============================================================
# Outputs — Service Role e Instance Profile
# ============================================================
output "ec2_role_arn" {
  description = "ARN do IAM role 6325257-technova-ec2-role"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_instance_profile_name" {
  description = "Nome do instance profile 6325257-technova-ec2-profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}
