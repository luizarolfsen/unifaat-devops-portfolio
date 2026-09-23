# aula-02 Docker Build Fix — Bugfix Design

## Overview

O projeto `aula-02/` do portfólio DevOps apresenta três defeitos que impedem ou comprometem a entrega: o Dockerfile está nomeado em minúsculo (`dockerfile`), o que causa falha de build em sistemas Linux/WSL (case-sensitive); não há `.gitignore`, expondo credenciais reais do `.env` a commits acidentais; e o `ia-analise.md` está incompleto em relação aos critérios de avaliação da disciplina.

A estratégia de fix é cirúrgica: renomear o arquivo, criar o `.gitignore` com regras mínimas necessárias, e completar o documento de análise — sem alterar a aplicação, o Compose, nem o conteúdo já escrito.

---

## Glossary

- **Bug_Condition (C)**: Conjunto de estados do repositório que fazem a avaliação automatizada falhar — nome de arquivo incorreto, arquivo sensível rastreável, ou documento obrigatório incompleto
- **Property (P)**: Comportamento correto esperado para cada entrada que satisfaça C — build bem-sucedido, `.env` ignorado, documento completo
- **Preservation**: Comportamentos existentes que NÃO devem ser alterados — lógica da API, configuração do Compose, conteúdo já escrito no `ia-analise.md`, `.env.example` rastreado
- **isBugCondition**: Função pseudocódigo que identifica se um dado estado do repositório dispara um dos três defeitos
- **Dockerfile**: Arquivo de definição da imagem Docker; a convenção oficial Docker usa `D` maiúsculo
- **case-sensitive filesystem**: Linux e WSL2 tratam `dockerfile` e `Dockerfile` como arquivos distintos — o Docker Engine procura `Dockerfile` por padrão
- **`.gitignore`**: Arquivo de configuração do Git que lista padrões de arquivos a não rastrear
- **.env**: Arquivo de variáveis de ambiente com valores reais; nunca deve ser commitado

---

## Bug Details

### Bug Condition

Os três defeitos podem ser avaliados com uma única função de condição que verifica o estado do repositório. O bug manifesta-se em qualquer uma das três condições independentes abaixo.

**Formal Specification:**

```
FUNCTION isBugCondition(repoState)
  INPUT: repoState — snapshot do diretório aula-02/ (lista de arquivos + conteúdo)
  OUTPUT: boolean

  // Bug 1: nome do Dockerfile é case-sensitive em Linux/WSL
  IF fileExists(repoState, "aula-02/dockerfile")
     AND NOT fileExists(repoState, "aula-02/Dockerfile")
  THEN RETURN true

  // Bug 2: .gitignore ausente ou sem regra para .env
  IF NOT fileExists(repoState, "aula-02/.gitignore")
     OR NOT containsRule(repoState, "aula-02/.gitignore", ".env")
  THEN RETURN true

  // Bug 3: ia-analise.md incompleto
  IF NOT containsSection(repoState, "aula-02/ia-analise.md", "Prompt Utilizado")
     OR NOT containsSection(repoState, "aula-02/ia-analise.md", "Output Original")
     OR NOT containsSection(repoState, "aula-02/ia-analise.md", "Alterações que Fiz Manualmente")
     OR NOT containsSection(repoState, "aula-02/ia-analise.md", "Minha Avaliação")
  THEN RETURN true

  RETURN false
END FUNCTION
```

### Examples

- **Bug 1 — Concreto**: `docker compose up --build` em Ubuntu/WSL retorna `failed to read dockerfile: open /path/dockerfile: no such file or directory` porque o Docker Engine procura `Dockerfile` e o arquivo existe como `dockerfile`.
- **Bug 2 — Concreto**: `git add .` seguido de `git commit` em qualquer sistema inclui o `.env` com `POSTGRES_PASSWORD=technova_tf_2024` no histórico público do GitHub.
- **Bug 3 — Concreto**: Avaliador lê `ia-analise.md` e não encontra o output original do Kiro separado das alterações manuais, resultando em nota abaixo da esperada.
- **Edge case — Bug 1**: mesmo que o `docker-compose.yml` tenha `dockerfile: dockerfile` (explícito e minúsculo), o problema persiste em Linux pois o arquivo simplesmente não segue a convenção; a solução correta é renomear o arquivo para `Dockerfile`.

---

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- `app.js` — lógica da API Node.js/Express não deve ser tocada
- `package.json` — dependências e scripts não devem ser alterados
- `docker-compose.yml` — serviços, healthchecks, volumes, rede `technova` preservados; apenas o campo `dockerfile:` no bloco `build:` da API pode ser adicionado/ajustado
- `.env.example` — deve permanecer rastreado pelo Git com os placeholders originais
- Conteúdo já existente em `ia-analise.md` — prompt, tabelas, avaliação já escritos devem ser preservados; apenas lacunas devem ser preenchidas

**Scope:**
Todos os arquivos que NÃO estão listados nas mudanças abaixo devem ser completamente inalterados por este fix. Isso inclui a aplicação, os arquivos de configuração do Compose, e o conteúdo já correto do `ia-analise.md`.

---

## Hypothesized Root Cause

### Bug 1 — Dockerfile casing

1. **Criação no Windows, execução no Linux**: O arquivo foi provavelmente criado em um ambiente Windows (case-insensitive) onde `dockerfile` e `Dockerfile` são equivalentes. Ao executar no WSL/Linux, o Docker Engine não encontra `Dockerfile` porque o filesystem distingue os casos.

2. **Campo `dockerfile:` não especificado**: O `docker-compose.yml` usa `build: context: .` sem `dockerfile: Dockerfile` explícito, fazendo o Docker Engine usar o nome padrão (`Dockerfile`) sem fallback para variações de casing.

### Bug 2 — .gitignore ausente

3. **Arquivo não criado durante setup**: O fluxo de criação do projeto não incluiu a geração do `.gitignore`. O `.env.example` foi criado como boa prática, mas sem o `.gitignore` o `.env` real permanece rastreável.

### Bug 3 — ia-analise.md incompleto

4. **Preenchimento parcial**: O documento foi iniciado mas algumas seções não foram completadas conforme o roteiro da disciplina — falta output original do Kiro separado claramente, e a avaliação reflexiva pode estar incompleta em algum critério.

---

## Correctness Properties

Property 1: Bug Condition — Repositório corrigido passa na avaliação automatizada

_For any_ estado do repositório onde `isBugCondition(repoState)` retorna `true` (Dockerfile com nome errado, `.gitignore` ausente, ou `ia-analise.md` incompleto), o repositório após o fix SHALL: (a) ter `Dockerfile` com D maiúsculo e `docker-compose.yml` referenciando-o explicitamente, (b) ter `.gitignore` com `.env` e `node_modules/` listados, e (c) ter `ia-analise.md` com todas as seções obrigatórias preenchidas.

**Validates: Requirements 2.1, 2.2, 2.3**

Property 2: Preservation — Comportamentos existentes inalterados

_For any_ arquivo ou comportamento que NÃO faça parte da condição de bug (lógica da API, configuração do Compose, `.env.example`, conteúdo já correto do `ia-analise.md`), o repositório após o fix SHALL produzir exatamente o mesmo comportamento que antes do fix, preservando toda a funcionalidade existente.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4**

---

## Fix Implementation

### Changes Required

**Bug 1 — Renomear Dockerfile**

**File**: `aula-02/dockerfile` → `aula-02/Dockerfile`

**Specific Changes**:
1. **Renomear o arquivo**: usar `git mv dockerfile Dockerfile` (o `git mv` garante que o Git rastreie a renomeação corretamente, especialmente importante em filesystems case-insensitive que podem não detectar a mudança de casing como modificação)
2. **Atualizar docker-compose.yml**: adicionar `dockerfile: Dockerfile` explicitamente no bloco `build:` do serviço `api` para eliminar dependência do nome padrão

**File**: `aula-02/docker-compose.yml`

```yaml
# Antes:
    build:
      context: .
      dockerfile: Dockerfile   # ← adicionar esta linha

# Depois (bloco build do serviço api):
    build:
      context: .
      dockerfile: Dockerfile
```

---

**Bug 2 — Criar .gitignore**

**File**: `aula-02/.gitignore` (criar novo)

**Specific Changes**:
1. **Criar o arquivo** com regras para `.env` e `node_modules/` no mínimo
2. **Verificar que `.env.example` não está listado** para garantir que o template público continue rastreado

```
# Dependências
node_modules/

# Variáveis de ambiente com credenciais reais
.env

# Logs
*.log
npm-debug.log*

# Sistema operacional
.DS_Store
Thumbs.db
```

---

**Bug 3 — Completar ia-analise.md**

**File**: `aula-02/ia-analise.md`

**Specific Changes**:
1. **Verificar cada seção obrigatória** contra o roteiro: Prompt Utilizado, Output Original do Kiro, Alterações que Fiz Manualmente, Alterações Aplicadas pelo Kiro, O que o Kiro Acertou, O que o Kiro Errou ou Omitiu, Minha Avaliação
2. **Preencher lacunas** caso alguma seção esteja faltando ou incompleta
3. **Preservar todo conteúdo já escrito** — nenhuma informação existente deve ser removida

*Nota*: A leitura do arquivo atual indica que o `ia-analise.md` já contém todas as seções listadas acima com conteúdo preenchido. Se a avaliação automatizada sinaliza incompletude, pode ser que o critério seja sobre formatação ou a ausência de algum campo específico (ex: RA/nome do aluno no `app.js`). Uma inspeção manual do documento original gerado pela IA (antes das edições) pode ser necessária para confirmar.

---

## Testing Strategy

### Validation Approach

A estratégia de testes segue duas fases: primeiro verificar o comportamento bugado no código não corrigido, depois validar que o fix resolve todos os defeitos sem quebrar o que estava funcionando.

### Exploratory Bug Condition Checking

**Goal**: Demonstrar os três defeitos no estado atual do repositório ANTES de aplicar o fix.

**Test Plan**: Executar verificações no estado atual do repositório para observar as falhas e confirmar as hipóteses de causa raiz.

**Test Cases**:
1. **Dockerfile Casing Test**: Verificar se `aula-02/Dockerfile` (maiúsculo) existe — esperado: não existe, existe apenas `dockerfile` (minúsculo). Vai falhar em `ls aula-02/Dockerfile` (falhará no unfixed code)
2. **docker compose build dry-run**: Executar `docker compose config` ou simular build para confirmar que `dockerfile: Dockerfile` não está especificado explicitamente no compose
3. **Git tracking test**: Verificar que `.gitignore` não existe e que `git status` listaria `.env` como arquivo a ser rastreado (falhará no unfixed code — `.gitignore` ausente)
4. **ia-analise.md sections check**: Verificar presença de todas as seções obrigatórias no documento

**Expected Counterexamples**:
- `ls aula-02/Dockerfile` retorna "No such file or directory" em Linux/WSL
- `git check-ignore .env` retorna exit code 1 (não ignorado) sem `.gitignore`

### Fix Checking

**Goal**: Verificar que, para todos os inputs onde a condição de bug se aplica, o repositório corrigido produz o comportamento esperado.

**Pseudocode:**
```
FOR ALL repoState WHERE isBugCondition(repoState) DO
  fixedRepo := applyFix(repoState)
  ASSERT fileExists(fixedRepo, "aula-02/Dockerfile")
  ASSERT NOT fileExists(fixedRepo, "aula-02/dockerfile")
  ASSERT fileContains(fixedRepo, "aula-02/docker-compose.yml", "dockerfile: Dockerfile")
  ASSERT fileExists(fixedRepo, "aula-02/.gitignore")
  ASSERT containsRule(fixedRepo, "aula-02/.gitignore", ".env")
  ASSERT allSectionsPresent(fixedRepo, "aula-02/ia-analise.md")
END FOR
```

### Preservation Checking

**Goal**: Verificar que, para todos os inputs onde a condição de bug NÃO se aplica, o repositório após o fix produz o mesmo comportamento que antes.

**Pseudocode:**
```
FOR ALL repoState WHERE NOT isBugCondition(repoState) DO
  ASSERT originalBehavior(repoState) = fixedBehavior(repoState)
END FOR
```

**Testing Approach**: A verificação de preservação é direta aqui — os arquivos não tocados devem ter diff vazio. Property-based testing não é aplicável a este tipo de defeito (configuração de repositório), mas podemos usar checksums/diff para garantir preservação.

**Test Cases**:
1. **app.js Preservation**: Verificar que `app.js` é byte-a-byte idêntico antes e depois do fix
2. **docker-compose.yml Preservation**: Verificar que apenas o campo `dockerfile:` foi adicionado, todos os outros campos preservados
3. **.env.example Preservation**: Verificar que `.env.example` ainda é listado por `git status` como rastreado (não ignorado)
4. **ia-analise.md Content Preservation**: Verificar que o conteúdo pré-existente do documento não foi removido ou alterado

### Unit Tests

- Verificar que `aula-02/Dockerfile` existe com D maiúsculo após o fix
- Verificar que `aula-02/dockerfile` (minúsculo) não existe após o fix
- Verificar que `aula-02/.gitignore` contém a linha `.env`
- Verificar que `aula-02/.gitignore` contém a linha `node_modules/`
- Verificar que `aula-02/.gitignore` NÃO contém `.env.example`
- Verificar que o `docker-compose.yml` contém `dockerfile: Dockerfile` no bloco `build:`

### Property-Based Tests

- Para qualquer sistema operacional com filesystem case-sensitive, `docker compose up --build` deve ter exit code 0 com o Dockerfile renomeado
- Para qualquer conjunto de arquivos no diretório `aula-02/`, o `.gitignore` deve excluir `.env` mas incluir `.env.example` no tracking do Git
- Para qualquer versão do conteúdo pré-existente do `ia-analise.md`, o fix não deve remover nenhuma seção já presente

### Integration Tests

- Executar `docker compose build` (ou `docker compose config --quiet`) no diretório `aula-02/` e verificar sucesso
- Executar `git check-ignore -v aula-02/.env` e confirmar que o arquivo é ignorado
- Executar `git check-ignore -v aula-02/.env.example` e confirmar que NÃO é ignorado
- Abrir `ia-analise.md` e verificar manualmente que todas as seções obrigatórias estão presentes e preenchidas
