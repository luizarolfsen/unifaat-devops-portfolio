# Requirements Document

## Introduction

Este documento especifica os requisitos para a criação de infraestrutura de rede AWS via Terraform para o projeto TechNova. A infraestrutura consiste em uma VPC com subnets públicas e privadas distribuídas em duas Availability Zones distintas, garantindo alta disponibilidade e isolamento de camadas.

## Glossary

- **Terraform_Module**: O conjunto de arquivos `.tf` que declara e provisiona os recursos AWS descritos neste documento.
- **VPC**: Virtual Private Cloud — rede virtual isolada dentro da AWS com bloco CIDR definido.
- **Subnet_Publica**: Subnet associada a uma Route Table que possui rota para um Internet Gateway, permitindo comunicação direta com a internet.
- **Subnet_Privada**: Subnet sem rota direta para a internet, destinada a recursos internos da aplicação.
- **Internet_Gateway**: Recurso AWS que viabiliza comunicação entre a VPC e a internet pública.
- **Route_Table**: Tabela de rotas AWS que define o roteamento de tráfego dentro da VPC.
- **AZ**: Availability Zone — data center fisicamente separado dentro de uma região AWS.
- **Tag**: Metadado chave-valor associado a recursos AWS para identificação e organização.
- **CIDR**: Classless Inter-Domain Routing — notação para definição de blocos de endereços IP.

---

## Requirements

### Requirement 1: Criação da VPC Principal

**User Story:** Como engenheiro de infraestrutura, eu quero provisionar uma VPC dedicada para o projeto TechNova, para que os recursos da aplicação operem em uma rede isolada e controlada.

#### Acceptance Criteria

1. THE Terraform_Module SHALL criar uma VPC com o bloco CIDR `10.0.0.0/16`.
2. THE Terraform_Module SHALL habilitar o suporte a DNS (`enable_dns_support = true`) na VPC.
3. THE Terraform_Module SHALL habilitar hostnames DNS (`enable_dns_hostnames = true`) na VPC.
4. THE Terraform_Module SHALL aplicar a tag `Name = "technova-vpc"` à VPC provisionada.

---

### Requirement 2: Criação das Subnets Públicas

**User Story:** Como engenheiro de infraestrutura, eu quero provisionar duas subnets públicas em Availability Zones distintas, para que os recursos com acesso à internet sejam distribuídos com alta disponibilidade.

#### Acceptance Criteria

1. THE Terraform_Module SHALL criar uma Subnet_Publica com CIDR `10.0.1.0/24` em uma AZ da região configurada.
2. THE Terraform_Module SHALL criar uma Subnet_Publica com CIDR `10.0.3.0/24` em uma AZ diferente da utilizada pelo CIDR `10.0.1.0/24`.
3. THE Terraform_Module SHALL associar cada Subnet_Publica à VPC criada no Requirement 1.
4. THE Terraform_Module SHALL aplicar tags de identificação (`Name`) a cada Subnet_Publica com valores distintos entre si.

---

### Requirement 3: Criação das Subnets Privadas

**User Story:** Como engenheiro de infraestrutura, eu quero provisionar duas subnets privadas em Availability Zones distintas, para que os recursos internos da aplicação operem de forma isolada e com alta disponibilidade.

#### Acceptance Criteria

1. THE Terraform_Module SHALL criar uma Subnet_Privada com CIDR `10.0.2.0/24` em uma AZ da região configurada.
2. THE Terraform_Module SHALL criar uma Subnet_Privada com CIDR `10.0.4.0/24` em uma AZ diferente da utilizada pelo CIDR `10.0.2.0/24`.
3. THE Terraform_Module SHALL associar cada Subnet_Privada à VPC criada no Requirement 1.
4. THE Terraform_Module SHALL aplicar tags de identificação (`Name`) a cada Subnet_Privada com valores distintos entre si.

---

### Requirement 4: Distribuição por Availability Zones

**User Story:** Como engenheiro de infraestrutura, eu quero garantir que as subnets estejam distribuídas entre pelo menos duas AZs distintas, para que a infraestrutura tolere a falha de uma AZ sem interrupção completa do serviço.

#### Acceptance Criteria

1. THE Terraform_Module SHALL alocar as subnets `10.0.1.0/24` e `10.0.2.0/24` na mesma AZ (AZ-A).
2. THE Terraform_Module SHALL alocar as subnets `10.0.3.0/24` e `10.0.4.0/24` na mesma AZ (AZ-B), diferente de AZ-A.
3. THE Terraform_Module SHALL utilizar o data source `aws_availability_zones` para obter dinamicamente as AZs disponíveis na região configurada, sem hardcode de nomes de AZ.

---

### Requirement 5: Internet Gateway e Roteamento Público

**User Story:** Como engenheiro de infraestrutura, eu quero que as subnets públicas tenham rota para a internet, para que recursos como load balancers e bastion hosts possam se comunicar externamente.

#### Acceptance Criteria

1. THE Terraform_Module SHALL criar um Internet_Gateway e associá-lo à VPC criada no Requirement 1.
2. THE Terraform_Module SHALL criar uma Route_Table pública com uma rota padrão (`0.0.0.0/0`) direcionada ao Internet_Gateway.
3. THE Terraform_Module SHALL associar cada Subnet_Publica à Route_Table pública criada neste requirement.
4. THE Terraform_Module SHALL aplicar a tag `Name` ao Internet_Gateway e à Route_Table pública com valores identificáveis.

---

### Requirement 6: Roteamento Privado

**User Story:** Como engenheiro de infraestrutura, eu quero que as subnets privadas utilizem uma Route Table local sem rota para a internet, para que os recursos internos permaneçam isolados do tráfego externo.

#### Acceptance Criteria

1. THE Terraform_Module SHALL criar uma Route_Table privada sem rota para o Internet_Gateway.
2. THE Terraform_Module SHALL associar cada Subnet_Privada à Route_Table privada criada neste requirement.
3. THE Terraform_Module SHALL aplicar a tag `Name` à Route_Table privada com valor identificável.

---

### Requirement 7: Consistência de Tagging

**User Story:** Como engenheiro de infraestrutura, eu quero que todos os recursos provisionados possuam a tag `Name` com valores coerentes ao projeto, para que o inventário de recursos AWS seja rastreável e organizado.

#### Acceptance Criteria

1. THE Terraform_Module SHALL aplicar a tag `Name` a todos os recursos AWS provisionados (VPC, subnets, Internet Gateway, Route Tables e associações de Route Table).
2. WHEN o Terraform_Module for executado, THE Terraform_Module SHALL produzir um plano (`terraform plan`) sem erros de validação relacionados a tags ausentes ou malformadas.
