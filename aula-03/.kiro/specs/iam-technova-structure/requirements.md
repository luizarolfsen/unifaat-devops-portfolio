# Requirements Document

## Introduction

This document specifies the requirements for provisioning an AWS IAM structure for the fictional company TechNova using Terraform. The configuration implements least-privilege access control through IAM groups, users, custom policies, a service role with instance profile, and enforces consistent resource tagging. All infrastructure is organized across dedicated Terraform files (`providers.tf`, `variables.tf`, `main.tf`, `policies.tf`, `roles.tf`, `outputs.tf`) to ensure maintainability. The spec covers the full lab exercise for the DevOps course at UniFAAT (Aula 03).

## Glossary

- **Terraform_Configuration**: The set of `.tf` files that collectively define the AWS IAM infrastructure managed by Terraform in this project.
- **IAM**: AWS Identity and Access Management — the AWS service used to control access to AWS resources.
- **IAM Group**: An IAM entity that contains IAM users and to which policies are attached, simplifying permission management.
- **IAM User**: An IAM entity representing a person or application that interacts with AWS.
- **IAM Policy**: A JSON document attached to IAM identities or resources that defines allowed or denied actions.
- **IAM Role**: An IAM identity with a trust policy that can be assumed by AWS services or other principals.
- **Instance Profile**: An AWS container for an IAM role that can be attached to an EC2 instance.
- **SEURA**: Placeholder prefix in resource names representing the student's RA (registration number), to be replaced with the actual RA value.
- **Mandatory Tag Set**: The fixed set of tags (`Project`, `ManagedBy`, `Aluno`, `RA`, `Disciplina`, `Aula`) that must be applied to every taggable IAM resource.
- **Parser**: A component that reads a structured text input and converts it into an in-memory representation.
- **Pretty_Printer**: A component that serializes an in-memory representation back into a formatted text output.

## Requirements

### Requirement 1: Terraform Provider Configuration

**User Story:** As a DevOps engineer, I want to declare and pin the AWS Terraform provider, so that the infrastructure can be initialized and validated consistently across environments.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL declare the `hashicorp/aws` provider inside a `required_providers` block with version constraint `~> 5.0`.
2. THE Terraform_Configuration SHALL configure the AWS provider with the attribute `region = "us-east-1"` in the provider block.
3. THE Terraform_Configuration SHALL declare all provider configuration in a dedicated `providers.tf` file that contains only provider-related blocks (no resource, variable, output, or module blocks).
4. IF the `providers.tf` file is absent or the provider block is missing, THEN `terraform init` and `terraform validate` SHALL fail with an error identifying the missing provider configuration.

---

### Requirement 2: Reusable Input Variables

**User Story:** As a DevOps engineer, I want to parameterize the configuration with input variables, so that the same code can be reused across different students and environments without modification.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL declare an input variable `project_name` of type `string` with a default value of `"TechNova"`.
2. THE Terraform_Configuration SHALL declare an input variable `environment` of type `string` with a default value of `"lab"`.
3. THE Terraform_Configuration SHALL declare an input variable `aluno` of type `string` with no default value and a description stating its purpose (student name).
4. THE Terraform_Configuration SHALL declare an input variable `ra` of type `string` with no default value and a description stating its purpose (student registration number).
5. THE Terraform_Configuration SHALL declare all input variables exclusively in a dedicated `variables.tf` file, with no variable blocks in any other file.
6. IF `terraform plan` is executed without providing a value for `aluno` or `ra`, THEN Terraform SHALL prompt for the missing value or error if run non-interactively.

---

### Requirement 3: IAM Groups

**User Story:** As a DevOps engineer, I want to create IAM groups for different team roles, so that permissions can be managed at the group level rather than per individual user.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL create an IAM group named exactly `SEURA-technova-developers`.
2. THE Terraform_Configuration SHALL create an IAM group named exactly `SEURA-technova-platform-eng`.
3. THE Terraform_Configuration SHALL tag both IAM groups with the mandatory tag set defined in Requirement 8.
4. IF the creation of either IAM group fails (e.g., name conflict), THEN the Terraform apply SHALL halt and output a human-readable error identifying the conflicting group name.
5. WHEN `terraform apply` is executed twice with the same configuration, THE Terraform_Configuration SHALL result in exactly two IAM groups with no duplicate groups created.

---

### Requirement 4: IAM Users and Group Memberships

**User Story:** As a DevOps engineer, I want to create IAM users and assign them to the appropriate groups, so that each team member has the correct permissions for their role.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL create an IAM user named exactly `SEURA-juliana-dev` with programmatic access enabled and console access disabled.
2. THE Terraform_Configuration SHALL create an IAM user named exactly `SEURA-rafael-platform` with programmatic access enabled and console access disabled.
3. THE Terraform_Configuration SHALL create an IAM user named exactly `SEURA-lucas-intern` with programmatic access enabled and console access disabled.
4. WHEN the Terraform_Configuration is applied, THE Terraform_Configuration SHALL assign `SEURA-juliana-dev` to the `SEURA-technova-developers` group such that the user is a member of exactly that one group.
5. WHEN the Terraform_Configuration is applied, THE Terraform_Configuration SHALL assign `SEURA-rafael-platform` to both the `SEURA-technova-developers` group and the `SEURA-technova-platform-eng` group such that the user is a member of exactly those two groups.
6. WHEN the Terraform_Configuration is applied, THE Terraform_Configuration SHALL assign `SEURA-lucas-intern` to the `SEURA-technova-developers` group such that the user is a member of exactly that one group.
7. THE Terraform_Configuration SHALL apply the mandatory tag set defined in Requirement 8 to all three IAM users, with no mandatory tag omitted.
8. THE Terraform_Configuration SHALL declare all IAM user resources, IAM group membership resources, and their tag blocks within a single file named `main.tf`, with no user, group, or membership resource declared in any other file.
9. IF the Terraform_Configuration is applied and any of the three IAM usernames already exists in the AWS account, THEN the Terraform_Configuration SHALL report a conflict error identifying the duplicate username and abort without modifying the existing user or its group memberships.

---

### Requirement 5: Custom IAM Policies and Group Attachments

**User Story:** As a DevOps engineer, I want to create fine-grained IAM policies and attach them to the appropriate groups, so that each group has only the permissions required for its function.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL create a custom IAM policy named `SEURA-technova-s3-read` that allows `s3:ListBucket` scoped to bucket-level resources matching the ARN pattern `arn:aws:s3:::technova-*`, and allows `s3:GetObject` scoped to object-level resources matching the ARN pattern `arn:aws:s3:::technova-*/*`.
2. THE Terraform_Configuration SHALL attach the `SEURA-technova-s3-read` policy to the `SEURA-technova-developers` group.
3. THE Terraform_Configuration SHALL create a custom IAM policy named `SEURA-technova-ec2-s3-full` that allows `ec2:Describe*` scoped to all resources (`*`), allows `ec2:StartInstances` and `ec2:StopInstances` only on EC2 instances carrying the tag `Project=TechNova` enforced via an IAM condition, allows `s3:ListBucket` scoped to bucket-level resources matching the ARN pattern `arn:aws:s3:::technova-*`, and allows `s3:GetObject` and `s3:PutObject` scoped to object-level resources matching the ARN pattern `arn:aws:s3:::technova-*/*`.
4. THE Terraform_Configuration SHALL attach the `SEURA-technova-ec2-s3-full` policy to the `SEURA-technova-platform-eng` group.
5. THE Terraform_Configuration SHALL create a custom IAM policy named `SEURA-technova-deny-destructive` that explicitly denies all actions matching the patterns `Delete*` and `Terminate*` across all AWS resources (`*`).
6. THE Terraform_Configuration SHALL attach the `SEURA-technova-deny-destructive` policy to the `SEURA-technova-developers` group.
7. THE Terraform_Configuration SHALL tag all three custom IAM policies with the mandatory tag set defined in Requirement 8.
8. THE Terraform_Configuration SHALL declare all custom policies and their group attachments in a dedicated `policies.tf` file.

---

### Requirement 6: EC2 Service Role and Instance Profile

**User Story:** As a DevOps engineer, I want to create an IAM role and instance profile for EC2 instances, so that applications running on EC2 can access S3 without embedding static credentials.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL create an IAM role named `SEURA-technova-ec2-role` with a trust policy that allows the `ec2.amazonaws.com` service principal to assume the role via the `sts:AssumeRole` action.
2. THE Terraform_Configuration SHALL attach a permissions policy to `SEURA-technova-ec2-role` that allows `s3:ListBucket` scoped to bucket-level resources matching the ARN pattern `arn:aws:s3:::technova-app-data-*`, and allows `s3:GetObject` and `s3:PutObject` scoped to object-level resources matching the ARN pattern `arn:aws:s3:::technova-app-data-*/*`, with no other S3 actions permitted.
3. THE Terraform_Configuration SHALL create an IAM instance profile named `SEURA-technova-ec2-profile` and associate it with `SEURA-technova-ec2-role`.
4. THE Terraform_Configuration SHALL tag `SEURA-technova-ec2-role` and `SEURA-technova-ec2-profile` with the mandatory tag set defined in Requirement 8.
5. THE Terraform_Configuration SHALL declare the service role, its permissions policy, and the instance profile in a dedicated `roles.tf` file.

---

### Requirement 7: Outputs

**User Story:** As a DevOps engineer, I want to expose key resource identifiers as Terraform outputs, so that other configurations or CI/CD pipelines can reference them without querying AWS directly.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL declare outputs named `user_juliana_arn`, `user_rafael_arn`, and `user_lucas_arn` containing the ARNs of the respective IAM users.
2. THE Terraform_Configuration SHALL declare outputs named `group_developers_name` and `group_platform_eng_name` containing the names of the respective IAM groups.
3. THE Terraform_Configuration SHALL declare outputs named `policy_s3_read_arn`, `policy_ec2_s3_full_arn`, and `policy_deny_destructive_arn` containing the ARNs of the respective custom IAM policies.
4. THE Terraform_Configuration SHALL declare an output named `ec2_role_arn` containing the ARN of `SEURA-technova-ec2-role`.
5. THE Terraform_Configuration SHALL declare an output named `ec2_instance_profile_name` containing the name of `SEURA-technova-ec2-profile`.
6. THE Terraform_Configuration SHALL declare all output blocks exclusively in a dedicated `outputs.tf` file, with no output blocks in any other file.

---

### Requirement 8: Mandatory Resource Tags

**User Story:** As a DevOps engineer, I want to apply a consistent set of tags to all IAM resources, so that resources can be tracked, audited, and attributed to the correct student and course context.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL apply the tag `Project = "TechNova"` to every IAM resource type that supports tagging (users, roles, policies).
2. THE Terraform_Configuration SHALL apply the tag `ManagedBy = "Terraform"` to every IAM resource type that supports tagging.
3. THE Terraform_Configuration SHALL apply the tag `Aluno` with the value of the `var.aluno` input variable to every IAM resource type that supports tagging.
4. THE Terraform_Configuration SHALL apply the tag `RA` with the value of the `var.ra` input variable to every IAM resource type that supports tagging.
5. THE Terraform_Configuration SHALL apply the tag `Disciplina = "DevOps - UniFAAT 2026-2"` to every IAM resource type that supports tagging.
6. THE Terraform_Configuration SHALL apply the tag `Aula = "03"` to every IAM resource type that supports tagging.
7. IF `var.aluno` or `var.ra` is provided as an empty string, THEN `terraform validate` SHALL produce a validation error indicating the variable must not be empty.

---

### Requirement 9: Version Control Hygiene

**User Story:** As a DevOps engineer, I want to include a properly configured `.gitignore`, so that Terraform-generated files and sensitive variable files are never accidentally committed to version control.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL include a `.gitignore` file that contains the entry `.terraform/` to exclude the Terraform plugin cache directory.
2. THE Terraform_Configuration SHALL include a `.gitignore` file that contains the entries `*.tfstate` and `*.tfstate.*` to exclude all state files.
3. THE Terraform_Configuration SHALL include a `.gitignore` file that contains the entry `*.tfvars` to prevent accidental commit of variable files that may contain secrets.
4. THE Terraform_Configuration SHALL include a `.gitignore` file that contains the entry `.terraform.lock.hcl` to exclude the dependency lock file.

---

### Requirement 10: Documentation

**User Story:** As a DevOps engineer, I want to include a `README.md` that explains the IAM design decisions, so that reviewers and future maintainers understand the structure without reading the Terraform code.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL include a `README.md` file that, for each IAM group, states its name, lists the policies attached to it, and describes the access level those policies collectively grant.
2. THE Terraform_Configuration SHALL include a `README.md` file that explains why the `SEURA-technova-deny-destructive` policy is attached to the `SEURA-technova-developers` group and describes at least one scenario it protects against.
3. THE Terraform_Configuration SHALL include a `README.md` file that explains the purpose of `SEURA-technova-ec2-role`, states that `SEURA-technova-ec2-profile` is required for EC2 attachment, and explains why an instance profile eliminates the need for static credentials.
4. THE Terraform_Configuration SHALL include a `README.md` file that lists the input variables `project_name`, `environment`, `aluno`, and `ra` by name and, for each, states whether it has a default value and what value or format is expected.
