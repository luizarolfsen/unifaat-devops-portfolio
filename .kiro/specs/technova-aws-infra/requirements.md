# Documento de Requisitos

## Introdução

Esta feature descreve o provisionamento completo da infraestrutura AWS para o projeto **TechNova** utilizando Terraform como ferramenta de Infrastructure as Code (IaC). O escopo abrange a criação de uma VPC isolada com sub-redes públicas e privadas em duas zonas de disponibilidade, configuração de roteamento e segurança de rede, provisionamento de uma instância EC2 com perfil IAM e inicialização automatizada da aplicação Node.js via User Data. Todos os recursos devem seguir um padrão de tagging consistente para rastreabilidade e governança.

---

## Glossário

- **Terraform**: Ferramenta de IaC da HashiCorp utilizada para declarar e provisionar recursos de infraestrutura na AWS.
- **VPC** *(Virtual Private Cloud)*: Rede virtual isolada na AWS onde os recursos do projeto são provisionados.
- **IGW** *(Internet Gateway)*: Componente que permite comunicação entre a VPC e a internet pública.
- **Route_Table**: Tabela de rotas que define para onde o tráfego de rede deve ser encaminhado dentro da VPC.
- **Security_Group**: Firewall virtual stateful que controla o tráfego de entrada e saída dos recursos AWS.
- **EC2_Instance**: Máquina virtual provisionada no serviço Amazon EC2.
- **AMI** *(Amazon Machine Image)*: Imagem de sistema operacional utilizada como base para criar a EC2_Instance.
- **Key_Pair**: Par de chaves SSH utilizado para acesso à EC2_Instance.
- **IAM_Role**: Identidade IAM que concede permissões a serviços AWS assumirem ações em nome do usuário.
- **IAM_Instance_Profile**: Contêiner que associa uma IAM_Role a uma EC2_Instance.
- **User_Data**: Script de inicialização executado automaticamente quando a EC2_Instance é iniciada pela primeira vez.
- **Subnet_Pública**: Sub-rede com rota para o IGW, onde instâncias podem receber IPs públicos.
- **Subnet_Privada**: Sub-rede sem rota para a internet, destinada a recursos internos como bancos de dados.
- **SG_API**: Security_Group associado à EC2_Instance da aplicação TechNova.
- **SG_DB**: Security_Group reservado para futuro uso com instâncias de banco de dados.
- **AZ** *(Availability Zone)*: Zona de disponibilidade física isolada dentro de uma região AWS.

---

## Requisitos

### Requisito 1: Provisionamento da VPC

**User Story:** Como estudante de DevOps, quero provisionar uma VPC dedicada ao projeto TechNova, para que todos os recursos da aplicação sejam isolados em uma rede virtual gerenciada.

#### Critérios de Aceitação

1. THE Terraform SHALL criar uma VPC com o bloco CIDR `10.0.0.0/16`.
2. THE Terraform SHALL habilitar suporte a DNS (`enable_dns_support = true`) na VPC.
3. THE Terraform SHALL habilitar hostnames DNS (`enable_dns_hostnames = true`) na VPC.
4. THE Terraform SHALL aplicar a tag `Name = "technova-vpc"` à VPC.
5. THE Terraform SHALL aplicar as tags padrão do projeto (`Project`, `Environment`, `ManagedBy`, `Owner`) à VPC.

---

### Requisito 2: Provisionamento das Sub-redes

**User Story:** Como estudante de DevOps, quero criar quatro sub-redes distribuídas em duas zonas de disponibilidade, para que a infraestrutura suporte separação entre camadas públicas (API/LB) e privadas (DB).

#### Critérios de Aceitação

1. THE Terraform SHALL criar uma Subnet_Pública com CIDR `10.0.1.0/24` na AZ `us-east-1a` com `map_public_ip_on_launch = true`.
2. THE Terraform SHALL criar uma Subnet_Pública com CIDR `10.0.3.0/24` na AZ `us-east-1b` com `map_public_ip_on_launch = true`.
3. THE Terraform SHALL criar uma Subnet_Privada com CIDR `10.0.2.0/24` na AZ `us-east-1a` com `map_public_ip_on_launch = false`.
4. THE Terraform SHALL criar uma Subnet_Privada com CIDR `10.0.4.0/24` na AZ `us-east-1b` com `map_public_ip_on_launch = false`.
5. THE Terraform SHALL associar todas as sub-redes à VPC definida no Requisito 1.
6. THE Terraform SHALL aplicar as tags padrão do projeto a cada sub-rede.

---

### Requisito 3: Configuração do Internet Gateway e Roteamento

**User Story:** Como estudante de DevOps, quero configurar um Internet Gateway e uma Route Table pública, para que as instâncias nas sub-redes públicas possam acessar e ser acessadas pela internet.

#### Critérios de Aceitação

1. THE Terraform SHALL criar um Internet Gateway e associá-lo à VPC.
2. THE Terraform SHALL criar uma Route_Table pública com uma rota `0.0.0.0/0` apontando para o IGW.
3. THE Terraform SHALL associar a Route_Table pública à Subnet_Pública `10.0.1.0/24` (us-east-1a).
4. THE Terraform SHALL associar a Route_Table pública à Subnet_Pública `10.0.3.0/24` (us-east-1b).
5. WHILE as Subnet_Privadas estiverem sem associação explícita de Route_Table, THE Terraform SHALL permitir que essas sub-redes utilizem apenas a Route_Table padrão da VPC, sem rota para a internet.
6. THE Terraform SHALL aplicar as tags padrão do projeto ao IGW e à Route_Table pública.

---

### Requisito 4: Configuração dos Security Groups

**User Story:** Como estudante de DevOps, quero criar Security Groups específicos para a API e para o banco de dados, para que o tráfego de rede seja controlado conforme a camada da aplicação.

#### Critérios de Aceitação

1. THE Terraform SHALL criar o SG_API com regra de ingresso permitindo tráfego TCP na porta 22 originado de `0.0.0.0/0`.
2. THE Terraform SHALL criar o SG_API com regra de ingresso permitindo tráfego TCP na porta 3000 originado de `0.0.0.0/0`.
3. THE Terraform SHALL criar o SG_API com regra de egresso permitindo todo o tráfego de saída (`0.0.0.0/0`).
4. THE Terraform SHALL criar o SG_DB com regra de ingresso permitindo tráfego TCP na porta 5432 originado exclusivamente do bloco CIDR `10.0.0.0/16`.
5. THE Terraform SHALL criar o SG_DB com regra de egresso permitindo todo o tráfego de saída (`0.0.0.0/0`).
6. THE Terraform SHALL associar o SG_API e o SG_DB à VPC definida no Requisito 1.
7. THE Terraform SHALL aplicar as tags padrão do projeto ao SG_API e ao SG_DB.

---

### Requisito 5: Provisionamento do Key Pair SSH

**User Story:** Como estudante de DevOps, quero que o Terraform gerencie o Key Pair SSH, para que o acesso à instância EC2 seja controlado e o material de chave seja produzido como output do Terraform.

#### Critérios de Aceitação

1. THE Terraform SHALL gerar um par de chaves SSH via recurso `tls_private_key` ou `aws_key_pair`.
2. THE Terraform SHALL registrar a chave pública na AWS como um `aws_key_pair`.
3. THE Terraform SHALL aplicar as tags padrão do projeto ao Key_Pair.
4. IF a chave privada já existir no estado do Terraform, THEN THE Terraform SHALL reutilizar o material existente sem regenerar o par de chaves.

---

### Requisito 6: Configuração do IAM Role e Instance Profile

**User Story:** Como estudante de DevOps, quero criar um IAM Role com permissão de leitura no S3 e associá-lo à instância EC2, para que a aplicação possa acessar buckets S3 sem credenciais embutidas no código.

#### Critérios de Aceitação

1. THE Terraform SHALL criar uma IAM_Role com trust policy permitindo que o serviço `ec2.amazonaws.com` assuma a role.
2. THE Terraform SHALL anexar a policy gerenciada `AmazonS3ReadOnlyAccess` à IAM_Role.
3. THE Terraform SHALL criar um IAM_Instance_Profile associando a IAM_Role criada.
4. THE Terraform SHALL aplicar as tags padrão do projeto à IAM_Role.

---

### Requisito 7: Provisionamento da Instância EC2

**User Story:** Como estudante de DevOps, quero provisionar uma instância EC2 na sub-rede pública com a aplicação Node.js inicializada automaticamente, para que o ambiente de desenvolvimento TechNova esteja operacional após o `terraform apply`.

#### Critérios de Aceitação

1. THE Terraform SHALL provisionar a EC2_Instance do tipo `t2.micro`.
2. THE Terraform SHALL selecionar a AMI mais recente do Amazon Linux 2023 utilizando o data source `aws_ami`.
3. THE Terraform SHALL lançar a EC2_Instance na Subnet_Pública `10.0.1.0/24` (us-east-1a).
4. THE Terraform SHALL associar o SG_API à EC2_Instance.
5. THE Terraform SHALL associar o Key_Pair definido no Requisito 5 à EC2_Instance.
6. THE Terraform SHALL associar o IAM_Instance_Profile definido no Requisito 6 à EC2_Instance.
7. THE Terraform SHALL fornecer um script de User_Data que instale o Node.js 18 na EC2_Instance.
8. THE Terraform SHALL fornecer um script de User_Data que instale o Git na EC2_Instance.
9. THE Terraform SHALL fornecer um script de User_Data que clone o repositório `technova-api` na EC2_Instance.
10. THE Terraform SHALL fornecer um script de User_Data que execute `npm install` no diretório clonado.
11. THE Terraform SHALL fornecer um script de User_Data que inicie a aplicação na porta 3000.
12. THE Terraform SHALL aplicar as tags padrão do projeto à EC2_Instance.

---

### Requisito 8: Padrão de Tagging de Recursos

**User Story:** Como estudante de DevOps, quero que todos os recursos AWS criados pelo Terraform possuam tags padronizadas, para que seja possível rastrear custos, identificar o ambiente e o responsável pelo recurso.

#### Critérios de Aceitação

1. THE Terraform SHALL aplicar a tag `Project = "TechNova"` a todos os recursos provisionados.
2. THE Terraform SHALL aplicar a tag `Environment = "development"` a todos os recursos provisionados.
3. THE Terraform SHALL aplicar a tag `ManagedBy = "Terraform"` a todos os recursos provisionados.
4. THE Terraform SHALL aplicar a tag `Owner` contendo o RA do aluno a todos os recursos provisionados.
5. THE Terraform SHALL aplicar a tag `Name` com o prefixo `technova-` seguido do identificador do recurso a todos os recursos provisionados.
6. IF um recurso for provisionado sem todas as cinco tags obrigatórias, THEN THE Terraform SHALL falhar na etapa de `plan` via política de validação ou variável obrigatória não fornecida.
