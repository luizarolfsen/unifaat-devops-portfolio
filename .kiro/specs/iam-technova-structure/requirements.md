# Requirements Document

## Introduction

This feature defines a complete AWS IAM structure for the TechNova project, provisioned entirely through Terraform. The structure implements the principle of least privilege, separating developer access from platform engineering access, applying explicit deny policies to protect destructive operations, and providing a service role for EC2 instances that need access to S3 buckets. The configuration is part of the DevOps discipline practical exercise at UniFAAT (2026-2, Aula 03).

## Glossary

- **IAM**: AWS Identity and Access Management — service that controls access to AWS resources.
- **Terraform_Configuration**: The set of `.tf` files managed by Terraform that declare infrastructure state.
- **IAM_Group**: A collection of IAM users that share a common set of permissions.
- **IAM_User**: An AWS identity representing a human or service that interacts with AWS resources.
- **IAM_Policy**: A JSON document that defines permissions (allow or deny) for AWS actions and resources.
- **IAM_Role**: An AWS identity with a trust policy that allows services or accounts to assume it.
- **Instance_Profile**: An IAM container for a role that can be assigned to an EC2 instance.
- **Group_Membership**: The association between an IAM user and one or more IAM groups.
- **Trust_Policy**: The policy document attached to a role that specifies which principals can assume it.
- **Least_Privilege**: The security principle of granting only the minimum permissions required to perform a task.
- **Tag**: A key-value metadata pair attached to AWS resources for identification and governance.
- **Destructive_Action**: Any AWS API action prefixed with `Delete*` or `Terminate*`.
- **Condition_Tag**: An IAM condition that restricts an action based on the presence of a specific resource tag.
- **technova-app-data-bucket**: Any S3 bucket whose name matches the prefix `technova-app-data-*`.
- **technova-bucket**: Any S3 bucket whose name matches the prefix `technova-*`.

---

## Requirements

### Requirement 1: Terraform Provider Configuration

**User Story:** As a DevOps engineer, I want a declared Terraform provider configuration, so that the infrastructure can be provisioned reproducibly against the correct AWS region.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL declare the `hashicorp/aws` provider with version constraint `~> 5.0`.
2. THE Terraform_Configuration SHALL configure the AWS provider to target the `us-east-1` region.
3. THE Terraform_Configuration SHALL declare all provider configuration in a dedicated `providers.tf` file.

---

### Requirement 2: Reusable Input Variables

**User Story:** As a DevOps engineer, I want input variables for project-wide settings, so that the configuration can be reused and customized without modifying resource definitions directly.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL declare an input variable `project_name` with a default value of `"TechNova"`.
2. THE Terraform_Configuration SHALL declare an input variable `environment` with a default value of `"lab"`.
3. THE Terraform_Configuration SHALL declare an input variable `aluno` that represents the student's name with no default value, making it required at plan time.
4. THE Terraform_Configuration SHALL declare an input variable `ra` that represents the student's registration number with no default value, making it required at plan time.
5. THE Terraform_Configuration SHALL declare all input variables in a dedicated `variables.tf` file.

---

### Requirement 3: IAM Groups

**User Story:** As a DevOps engineer, I want IAM groups that logically separate developer and platform engineering teams, so that permissions can be managed at the group level rather than per user.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL create an IAM group named `SEURA-technova-developers`.
2. THE Terraform_Configuration SHALL create an IAM group named `SEURA-technova-platform-eng`.
3. THE Terraform_Configuration SHALL tag both IAM groups with the mandatory tag set defined in Requirement 8.

---

### Requirement 4: IAM Users and Group Memberships

**User Story:** As a DevOps engineer, I want IAM users created and assigned to the appropriate groups, so that each person has the correct access level according to their role.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL create an IAM user named `SEURA-juliana-dev`.
2. THE Terraform_Configuration SHALL create an IAM user named `SEURA-rafael-platform`.
3. THE Terraform_Configuration SHALL create an IAM user named `SEURA-lucas-intern`.
4. THE Terraform_Configuration SHALL assign `SEURA-juliana-dev` to the `SEURA-technova-developers` group.
5. THE Terraform_Configuration SHALL assign `SEURA-rafael-platform` to both the `SEURA-technova-developers` group and the `SEURA-technova-platform-eng` group.
6. THE Terraform_Configuration SHALL assign `SEURA-lucas-intern` to the `SEURA-technova-developers` group.
7. THE Terraform_Configuration SHALL tag all three IAM users with the mandatory tag set defined in Requirement 8.
8. THE Terraform_Configuration SHALL declare all users, groups, and group memberships in a dedicated `main.tf` file.

---

### Requirement 5: Custom IAM Policies and Group Attachments

**User Story:** As a DevOps engineer, I want custom IAM policies following the principle of least privilege, so that each group has only the permissions it needs and destructive operations are explicitly denied.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL create a custom IAM policy named `SEURA-technova-s3-read` that allows the actions `s3:GetObject` and `s3:ListBucket` scoped to resources matching the `technova-*` bucket prefix.
2. THE Terraform_Configuration SHALL attach the `SEURA-technova-s3-read` policy to the `SEURA-technova-developers` group.
3. THE Terraform_Configuration SHALL create a custom IAM policy named `SEURA-technova-ec2-s3-full` that allows `ec2:Describe*` on all EC2 resources, allows `ec2:StartInstances` and `ec2:StopInstances` only on instances that carry the tag `Project=TechNova` (enforced via an IAM condition), and allows `s3:GetObject`, `s3:PutObject`, and `s3:ListBucket` scoped to resources matching the `technova-*` bucket prefix.
4. THE Terraform_Configuration SHALL attach the `SEURA-technova-ec2-s3-full` policy to the `SEURA-technova-platform-eng` group.
5. THE Terraform_Configuration SHALL create a custom IAM policy named `SEURA-technova-deny-destructive` that explicitly denies all actions matching the pattern `Delete*` and `Terminate*` across all AWS resources.
6. THE Terraform_Configuration SHALL attach the `SEURA-technova-deny-destructive` policy to the `SEURA-technova-developers` group.
7. THE Terraform_Configuration SHALL tag all three custom IAM policies with the mandatory tag set defined in Requirement 8.
8. THE Terraform_Configuration SHALL declare all custom policies and their group attachments in a dedicated `policies.tf` file.

---

### Requirement 6: EC2 Service Role and Instance Profile

**User Story:** As a DevOps engineer, I want a service role for EC2 instances, so that applications running on EC2 can access TechNova S3 buckets without requiring static credentials.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL create an IAM role named `SEURA-technova-ec2-role` with a trust policy that allows the `ec2.amazonaws.com` service principal to assume the role via the `sts:AssumeRole` action.
2. THE Terraform_Configuration SHALL attach a permissions policy to `SEURA-technova-ec2-role` that allows `s3:GetObject`, `s3:PutObject`, and `s3:ListBucket` scoped to resources matching the `technova-app-data-*` bucket prefix.
3. THE Terraform_Configuration SHALL create an IAM instance profile named `SEURA-technova-ec2-profile` and associate it with `SEURA-technova-ec2-role`.
4. THE Terraform_Configuration SHALL tag `SEURA-technova-ec2-role` and `SEURA-technova-ec2-profile` with the mandatory tag set defined in Requirement 8.
5. THE Terraform_Configuration SHALL declare the service role, its permissions policy, and the instance profile in a dedicated `roles.tf` file.

---

### Requirement 7: Outputs

**User Story:** As a DevOps engineer, I want Terraform outputs for all key resource identifiers, so that other Terraform modules or CI/CD pipelines can consume the provisioned IAM resource references without querying AWS directly.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL output the ARN of each IAM user (`SEURA-juliana-dev`, `SEURA-rafael-platform`, `SEURA-lucas-intern`).
2. THE Terraform_Configuration SHALL output the name of each IAM group (`SEURA-technova-developers`, `SEURA-technova-platform-eng`).
3. THE Terraform_Configuration SHALL output the ARN of each custom IAM policy (`SEURA-technova-s3-read`, `SEURA-technova-ec2-s3-full`, `SEURA-technova-deny-destructive`).
4. THE Terraform_Configuration SHALL output the ARN of the IAM role `SEURA-technova-ec2-role`.
5. THE Terraform_Configuration SHALL output the name of the IAM instance profile `SEURA-technova-ec2-profile`.
6. THE Terraform_Configuration SHALL declare all outputs in a dedicated `outputs.tf` file.

---

### Requirement 8: Mandatory Resource Tags

**User Story:** As a DevOps engineer, I want all AWS resources to carry a standard set of tags, so that resources can be identified, attributed to the correct course exercise, and governed through tag-based policies.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL apply the tag `Project = "TechNova"` to every IAM resource it creates.
2. THE Terraform_Configuration SHALL apply the tag `ManagedBy = "Terraform"` to every IAM resource it creates.
3. THE Terraform_Configuration SHALL apply the tag `Aluno` with the value of the `var.aluno` input variable to every IAM resource it creates.
4. THE Terraform_Configuration SHALL apply the tag `RA` with the value of the `var.ra` input variable to every IAM resource it creates.
5. THE Terraform_Configuration SHALL apply the tag `Disciplina = "DevOps - UniFAAT 2026-2"` to every IAM resource it creates.
6. THE Terraform_Configuration SHALL apply the tag `Aula = "03"` to every IAM resource it creates.

---

### Requirement 9: Version Control Hygiene

**User Story:** As a DevOps engineer, I want a `.gitignore` file configured for Terraform projects, so that generated files, state files, and secrets are never accidentally committed to the repository.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL include a `.gitignore` file that excludes `.terraform/` directories.
2. THE Terraform_Configuration SHALL include a `.gitignore` file that excludes `*.tfstate` and `*.tfstate.*` files.
3. THE Terraform_Configuration SHALL include a `.gitignore` file that excludes `*.tfvars` files (to prevent accidental credential commits).
4. THE Terraform_Configuration SHALL include a `.gitignore` file that excludes `.terraform.lock.hcl` from version tracking unless the team explicitly decides to pin it.

---

### Requirement 10: Documentation

**User Story:** As a student, I want a README explaining the IAM design decisions, so that the exercise demonstrates understanding of least-privilege principles and Terraform best practices.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL include a `README.md` file that describes the purpose of each IAM group and the access level it grants.
2. THE Terraform_Configuration SHALL include a `README.md` file that explains the rationale for attaching the `SEURA-technova-deny-destructive` policy to the developers group.
3. THE Terraform_Configuration SHALL include a `README.md` file that describes the EC2 service role and why an instance profile is used instead of static credentials.
4. THE Terraform_Configuration SHALL include a `README.md` file that lists all required Terraform variables and their purpose.
