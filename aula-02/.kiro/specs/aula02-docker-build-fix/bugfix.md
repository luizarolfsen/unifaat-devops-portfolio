# aula-02 Docker Build Fix — Bugfix Requirements

## Introduction

A avaliação automatizada da entrega TF Aula 02 identificou três problemas críticos no projeto `aula-02/` do portfólio DevOps. Esses problemas comprometem a construção da imagem Docker em ambientes Linux/WSL (filesystem case-sensitive), expõem credenciais reais a commits acidentais, e deixam a reflexão de IA incompleta conforme exigido pelo roteiro da disciplina.

---

## Requirements

### 1. Bug Conditions (O que está errado)

#### 1.1 Dockerfile com nome incorreto (case-sensitive)

O arquivo de definição da imagem Docker está nomeado `dockerfile` (todo minúsculo). Em sistemas Linux e WSL — onde o filesystem é case-sensitive — o Docker Engine procura por `Dockerfile` (D maiúsculo) como convenção padrão. Quando o `docker-compose.yml` especifica `build: context: .` sem um campo `dockerfile:` explícito apontando para o nome correto, o build falha com "failed to read dockerfile".

**Condição de bug:** o arquivo existe como `aula-02/dockerfile` em vez de `aula-02/Dockerfile`.

#### 1.2 `.gitignore` ausente

Não existe arquivo `.gitignore` em `aula-02/`. O arquivo `.env` contém credenciais reais (`POSTGRES_PASSWORD=technova_tf_2024`, `DB_PASSWORD=technova_tf_2024`). Sem um `.gitignore` configurado, qualquer `git add .` ou `git add -A` incluirá o `.env` no commit, expondo as credenciais no histórico do repositório.

**Condição de bug:** ausência de `aula-02/.gitignore` com regra para ignorar `.env`.

#### 1.3 `ia-analise.md` incompleto

O arquivo `aula-02/ia-analise.md` existe, mas a seção de alterações aplicadas pelo Kiro está incompleta e a avaliação reflexiva não cobre todos os itens exigidos pelo roteiro: prompt original detalhado, output completo do Kiro antes de qualquer modificação manual, tabela de alterações com justificativas, e avaliação crítica sobre o uso da IA.

**Condição de bug:** o documento de análise de IA não satisfaz todos os critérios de avaliação da disciplina.

---

### 2. Expected Behavior (O que deve acontecer após o fix)

#### 2.1 Build Docker funciona em Linux/WSL

Após o fix, `docker compose up --build` deve encontrar o Dockerfile sem erros em qualquer sistema operacional, incluindo Linux e WSL com filesystem case-sensitive.

- O arquivo deve se chamar `Dockerfile` (D maiúsculo, restante minúsculo) — convenção oficial Docker.
- O `docker-compose.yml` deve referenciar `dockerfile: Dockerfile` explicitamente no bloco `build:` para eliminar ambiguidade.

#### 2.2 Credenciais não são commitadas acidentalmente

Após o fix, o arquivo `.env` deve ser ignorado pelo Git. O `.gitignore` deve conter ao menos:

- `.env` (para ignorar o arquivo de credenciais)
- `node_modules/` (para ignorar dependências)

O arquivo `.env.example` **não** deve ser ignorado — ele é o template público sem valores sensíveis.

#### 2.3 `ia-analise.md` completo e avaliável

Após o fix, o documento deve conter obrigatoriamente:

- Prompt original enviado à IA (completo, sem omissões)
- Output original da IA antes de qualquer edição manual
- Tabela de alterações manuais com coluna "O que mudei" e "Por quê"
- Avaliação reflexiva com: tempo economizado, tempo gasto em validação/correção, nota para o output (1–10), e resposta à pergunta "usaria novamente?"

---

### 3. Unchanged Behavior (O que não deve mudar)

#### 3.1 Funcionalidade da aplicação Node.js preservada

O `app.js`, `package.json`, e a lógica da API não devem ser alterados.

#### 3.2 Configuração do Docker Compose preservada

A estrutura de serviços (`api`, `postgres`, `redis`), healthchecks, `depends_on`, volumes nomeados, e rede `technova` no `docker-compose.yml` não devem ser alterados — apenas a referência ao `dockerfile:` no bloco `build:` da API pode ser adicionada.

#### 3.3 `.env.example` preservado

O arquivo `.env.example` com os placeholders deve permanecer rastreado pelo Git e inalterado.

#### 3.4 Conteúdo existente do `ia-analise.md` preservado

O conteúdo já escrito no `ia-analise.md` (prompt, output do Kiro, tabelas existentes, análise) deve ser preservado — apenas completado onde estiver faltando informação.
