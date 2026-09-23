# Aula 03 — Terraform + IAM | Luiza Carneiro Rolfsen (RA: 6325257)

**Disciplina:** DevOps - UniFAAT 2026-2  
**Aula:** 03  
**Aluno:** Luiza Carneiro Rolfsen  
**RA:** 6325257  
**Projeto:** TechNova  

---

## Visão Geral

Este exercício provisiona uma estrutura IAM completa na AWS usando Terraform, seguindo o princípio do menor privilégio. Todos os recursos são tagueados e organizados em arquivos separados por responsabilidade.

---

## Estrutura de Arquivos

| Arquivo | Conteúdo |
|---|---|
| `providers.tf` | Provider AWS (`hashicorp/aws ~> 5.0`, região `us-east-1`) |
| `variables.tf` | Variáveis reutilizáveis (`project_name`, `environment`, `aluno`, `ra`) |
| `main.tf` | Grupos, usuários e memberships |
| `policies.tf` | 3 custom policies + attachments aos grupos |
| `roles.tf` | Service role EC2, policy de permissões e instance profile |
| `outputs.tf` | ARNs de usuários, grupos, policies, role e profile |
| `.gitignore` | Exclusão de arquivos gerados pelo Terraform |

---

## Design da Estrutura IAM

A estrutura foi pensada para separar responsabilidades entre dois perfis distintos dentro da TechNova: desenvolvedores, que precisam apenas ler dados do S3, e engenheiros de plataforma, que operam a infraestrutura EC2 e têm acesso de escrita no S3.

Criei dois grupos (`6325257-technova-developers` e `6325257-technova-platform-eng`) porque a separação por grupo permite gerenciar permissões coletivamente — se um novo dev entrar na empresa, basta adicioná-lo ao grupo `developers` e ele já herda as policies corretas, sem precisar configurar permissões individuais.

O usuário `6325257-rafael-platform` pertence aos dois grupos intencionalmente: ele é engenheiro de plataforma mas também precisa dos controles do grupo `developers`, incluindo a proteção contra ações destrutivas.

---

## Grupos IAM

### `6325257-technova-developers`

**Propósito:** Representa o time de desenvolvimento da TechNova.  
**Políticas anexadas:**
- `6325257-technova-s3-read` — permite leitura (`ListBucket`, `GetObject`) em buckets com prefixo `technova-*`
- `6325257-technova-deny-destructive` — nega explicitamente qualquer ação `Delete*` ou `Terminate*` em todos os recursos

**Nível de acesso:** Leitura em S3 TechNova. Sem capacidade de deletar ou encerrar recursos.

---

### `6325257-technova-platform-eng`

**Propósito:** Representa o time de engenharia de plataforma, responsável por operar a infraestrutura.  
**Políticas anexadas:**
- `6325257-technova-ec2-s3-full` — permite `ec2:Describe*` em todos os recursos, `ec2:StartInstances`/`ec2:StopInstances` somente em instâncias com a tag `Project=TechNova`, e leitura/escrita em S3 `technova-*`

**Nível de acesso:** Operação de instâncias EC2 tagueadas + leitura e escrita em S3 TechNova.

---

## Usuários IAM

| Usuário | Grupo(s) | Perfil |
|---|---|---|
| `6325257-juliana-dev` | `developers` | Desenvolvedora — acesso leitura S3 |
| `6325257-rafael-platform` | `developers` + `platform-eng` | Engenheiro de plataforma — acesso completo EC2/S3 |
| `6325257-lucas-intern` | `developers` | Estagiário — somente leitura via policy do grupo |

---

## Políticas Customizadas

### `6325257-technova-s3-read`
Concede acesso de leitura mínimo ao S3:
- `s3:ListBucket` → `arn:aws:s3:::technova-*`
- `s3:GetObject` → `arn:aws:s3:::technova-*/*`

### `6325257-technova-ec2-s3-full`
Acesso operacional para plataforma:
- `ec2:Describe*` → todos os recursos (`*`)
- `ec2:StartInstances` / `ec2:StopInstances` → somente instâncias com tag `Project=TechNova` (Condition)
- `s3:ListBucket` → `arn:aws:s3:::technova-*`
- `s3:GetObject` / `s3:PutObject` → `arn:aws:s3:::technova-*/*`

### `6325257-technova-deny-destructive`
Camada de proteção extra aplicada ao grupo `developers`:
- `Deny` explícito para `Delete*` e `Terminate*` em todos os recursos (`*`)

**Racional do deny-destructive:** Mesmo que uma policy futura conceda permissões mais amplas ao grupo `developers`, o deny explícito sempre prevalece na avaliação de políticas IAM (Deny > Allow). Isso garante que nenhum desenvolvedor consiga deletar buckets S3, snapshots, instâncias EC2 ou qualquer outro recurso crítico — mesmo que receba temporariamente uma policy mais permissiva para um hotfix.

---

## Princípio do Menor Privilégio

O princípio do menor privilégio define que cada usuário, sistema ou processo deve ter acesso apenas ao mínimo necessário para realizar sua função — nada além disso.

**Dois exemplos de aplicação neste projeto:**

1. **Policy `6325257-technova-s3-read`:** Em vez de conceder `s3:*` (acesso total), a policy permite apenas `s3:ListBucket` e `s3:GetObject`, e restringe o escopo ao padrão de bucket `technova-*`. Um dev não pode escrever, deletar ou acessar buckets de outros projetos.

2. **Condition na policy `6325257-technova-ec2-s3-full`:** Os engenheiros de plataforma podem iniciar e parar instâncias EC2, mas somente as que têm a tag `Project=TechNova`. Isso impede que eles operem instâncias de outros projetos ou ambientes por engano.

**O que aconteceria com `AmazonS3FullAccess`?** O grupo `developers` teria `s3:*` em `*` — poderia deletar qualquer bucket da conta, listar buckets de outros projetos, tornar objetos públicos, modificar ACLs. Um estagiário como `lucas-intern` teria exatamente os mesmos poderes que o time de infraestrutura. A custom policy elimina esse risco ao nomear ações e recursos explicitamente.

---

## Diagrama de Permissões

```
Usuários → Grupos → Policies → Recursos AWS

6325257-juliana-dev   ──┐
6325257-rafael-platform ─┤── developers ──── s3-read ──────── S3 technova-*  (ListBucket, GetObject)
6325257-lucas-intern  ──┘                └── deny-destructive ─ * (Deny Delete*, Terminate*)

6325257-rafael-platform ─── platform-eng ── ec2-s3-full ───── EC2 tag:Project=TechNova (Start/Stop)
                                                          └─── S3 technova-*  (List, Get, Put)

EC2 Instance ──── Instance Profile ──── 6325257-technova-ec2-role ──── S3 technova-app-data-* (List, Get, Put)
```

---

## Service Role — EC2 → S3

### `6325257-technova-ec2-role`

**Propósito:** Permite que instâncias EC2 da TechNova acessem buckets S3 de dados da aplicação (`technova-app-data-*`) sem credenciais estáticas.

**Trust Policy:** `ec2.amazonaws.com` pode assumir o role via `sts:AssumeRole`.

**Permissões:**
- `s3:ListBucket` → `arn:aws:s3:::technova-app-data-*`
- `s3:GetObject` / `s3:PutObject` → `arn:aws:s3:::technova-app-data-*/*`

### `6325257-technova-ec2-profile`

O Instance Profile é o contêiner IAM que faz a ponte entre o role e a instância EC2. As credenciais são rotacionadas automaticamente pelo serviço de metadados da instância (IMDS), eliminando o risco de credenciais estáticas expostas em código ou variáveis de ambiente.

---

## Variáveis de Entrada

| Variável | Tipo | Default | Obrigatória | Descrição |
|---|---|---|---|---|
| `project_name` | `string` | `"TechNova"` | Não | Nome do projeto, usado nas tags |
| `environment` | `string` | `"lab"` | Não | Ambiente de deployment |
| `aluno` | `string` | — | **Sim** | Nome completo do aluno |
| `ra` | `string` | — | **Sim** | Registro Acadêmico (RA) do aluno |

---

## Comandos Utilizados

```bash
# Inicializar o Terraform (baixar provider AWS)
terraform init

# Validar a configuração
terraform validate

# Visualizar o plano de execução
terraform plan -var="aluno=Luiza Carneiro Rolfsen" -var="ra=6325257"

# Aplicar a infraestrutura
terraform apply -var="aluno=Luiza Carneiro Rolfsen" -var="ra=6325257"

# Destruir após capturar evidências
terraform destroy -var="aluno=Luiza Carneiro Rolfsen" -var="ra=6325257"
```

---

## Reflexão: Console AWS vs. Terraform

Criar IAM pelo Console AWS é rápido para recursos pontuais, mas não escala: cada clique é efêmero, sem histórico de quem mudou o quê ou por quê. Se um colega de equipe precisar replicar o ambiente, ele vai clicar nos mesmos passos sem garantia de consistência.

Com Terraform, toda a estrutura IAM vira código versionado no Git. Qualquer mudança passa por pull request, revisão e aprovação antes de ser aplicada. O estado declarativo garante que o ambiente real sempre corresponde ao que está no repositório. Para uma equipe DevOps, isso é essencial: auditabilidade, reprodutibilidade e rollback são nativos do processo, não um esforço extra.

---

## Tags Obrigatórias

Todos os recursos IAM que suportam tags recebem:

```hcl
tags = {
  Project    = "TechNova"
  ManagedBy  = "Terraform"
  Aluno      = "Luiza Carneiro Rolfsen"
  RA         = "6325257"
  Disciplina = "DevOps - UniFAAT 2026-2"
  Aula       = "03"
}
```

> **Nota:** IAM Groups não suportam tags na API AWS. Usuários, roles e policies gerenciadas recebem todas as tags.
