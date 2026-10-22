# Análise: IA no CI/CD — Aula 09

**Aluno:** Luiza Carneiro Rolfsen  
**RA:** 6325257  
**Data:** 22/10/2026

---

## 1. Por que o Amazon ECR foi escolhido como registry

### Escolha pelo ECR

O Amazon ECR (Elastic Container Registry) foi escolhido por estar integrado nativamente ao ecossistema AWS. Em um pipeline que já usa credenciais AWS (via `aws sts get-caller-identity`) e que futuramente pode fazer deploy em ECS ou EKS, o ECR elimina a necessidade de gerenciar credenciais adicionais — o mesmo IAM role que autentica o pipeline já autoriza o push de imagens.

### Comparação com alternativas

| Registry | Vantagem | Desvantagem no contexto |
|----------|----------|------------------------|
| **Amazon ECR** | Integração nativa com AWS IAM, sem credencial extra | Depende de sessão AWS ativa |
| **GitHub Container Registry (ghcr.io)** | Integrado ao GitHub, sem custo extra para repos públicos | Requer token separado; não integra com AWS diretamente |
| **Docker Hub** | Universal, amplamente conhecido | Rate limiting em pulls (100/6h sem autenticação); requer conta e token |

### Restrições do Learner Lab

O AWS Academy Learner Lab impõe limitações importantes que influenciaram a implementação:

- **Credenciais temporárias:** `aws_access_key_id`, `aws_secret_access_key` e `aws_session_token` mudam a cada sessão. O `aws_session_token` é obrigatório e não existe em contas AWS normais.
- **Sessão limitada:** O Lab expira automaticamente após algumas horas, invalidando todas as credenciais.
- **Sem automação de renovação:** Não é possível configurar credenciais permanentes para o GitHub Actions — cada nova sessão exige atualização manual dos secrets no repositório.
- **Região fixa:** O Lab opera em `us-east-1`, sem opção de troca.

Por isso, o `ecr-push.sh` foi projetado para uso local (com credenciais já carregadas no `~/.aws/credentials`), não como workflow automático no GitHub Actions.

---

## 2. Estratégia de tagging

### Tags utilizadas

O script `ecr-push.sh` publica cada imagem com duas tags:

```
<account>.dkr.ecr.us-east-1.amazonaws.com/technova-api:sha-<git-short-sha>
<account>.dkr.ecr.us-east-1.amazonaws.com/technova-api:latest
```

### Por que essa estratégia

**Tag por SHA do commit (`sha-abc1234`):**
- Rastreabilidade total: cada imagem é identificada pelo commit exato que a gerou
- Permite rollback preciso — para voltar a uma versão anterior, basta fazer pull pela tag SHA
- Imutável: um SHA nunca muda, eliminando ambiguidade sobre "qual versão está rodando"

**Tag `latest`:**
- Convenção universal do Docker para "versão mais recente"
- Facilita testes locais e pull sem precisar conhecer o SHA
- Sempre aponta para o último push bem-sucedido

### Por que não foi usada tag semver (`1.0.0`)

A tag semver exige versionamento manual ou uma pipeline mais elaborada com leitura do `package.json`. Para o escopo do lab, SHA + latest cobre os casos de uso principais. Em produção, o ideal seria combinar as três: `sha-abc1234`, `1.0.0` e `latest`.

---

## 3. Padrões verificados pelo AI Review

O script `ai-review.js` analisa o diff do PR linha por linha, verificando apenas as linhas **adicionadas** (`+`). Os padrões são divididos por severidade:

### 🔴 CRITICAL — bloqueiam o merge

| Padrão | Risco |
|--------|-------|
| `(password\|secret\|key\|token)\s*[:=]\s*['"][^'"]+['"]` | Credencial hardcoded no código |
| `eval\s*\(` | Code injection via `eval()` |
| `exec\(...\${` | Command injection via template literal |
| `query\(...\+` | SQL injection por concatenação de string |

### 🟡 WARNING — alertas, não bloqueiam

| Padrão | Risco |
|--------|-------|
| `console\.(log\|debug\|info)\(` | Vazamento de informação em produção |
| `catch\s*\(\s*\w*\s*\)\s*\{\s*\}` | Erros silenciados (catch vazio) |
| `0\.0\.0\.0\|INADDR_ANY` | Binding em todas as interfaces — verificar intencionalidade |

### 🔵 INFO — informativos

| Padrão | Situação |
|--------|----------|
| `TODO\|FIXME\|HACK\|XXX` | Pendências técnicas não resolvidas |

---

## 4. Lógica e prompt da análise

O script **não usa um modelo de linguagem (LLM)** — a análise é feita por **pattern matching com expressões regulares**. Essa abordagem foi escolhida para o lab por ser determinística, sem custo de API e sem dependência de serviços externos.

### Fluxo de execução

```
1. Obter diff do PR via git diff origin/<base>...HEAD
2. Percorrer cada linha do diff
3. Filtrar apenas linhas adicionadas (prefixo +)
4. Ignorar linhas de definição de padrões (evitar falsos positivos do próprio script)
5. Para cada linha, testar contra todos os SECURITY_PATTERNS
6. Acumular findings com arquivo, linha, código e severidade
7. Gerar relatório markdown
8. Postar como comentário no PR via GitHub API
9. Se houver CRITICAL → process.exit(1) → workflow falha → PR bloqueado
```

### Como seria com IA real

Em produção, o passo 4 seria substituído por uma chamada ao Amazon Bedrock ou OpenAI, enviando o diff como prompt:

```
Analise este diff de código como um especialista em segurança.
Identifique: credenciais hardcoded, injeções, erros silenciados,
más práticas de produção. Classifique por CRITICAL/WARNING/INFO.
Diff: <conteúdo do diff>
```

---

## 5. Quando confiar na IA vs quando exige review humano

### Pode confiar na análise automática

- Detecção de padrões textuais óbvios: credenciais com aspas, `eval()`, `console.log`
- Verificações de conformidade com regras fixas (linting, formatação)
- Triagem inicial para priorizar o que o revisor humano deve olhar primeiro
- Detecção de regressões em arquivos críticos conhecidos

### Exige review humano obrigatório

- **Lógica de negócio:** a IA não entende o contexto do domínio — uma validação "incorreta" pode ser intencional
- **Segurança em profundidade:** fluxos de autenticação/autorização exigem raciocínio sobre estado e sequência de chamadas
- **Race conditions e problemas de concorrência:** pattern matching não detecta isso
- **Impacto em dados:** migrações de banco, mudanças de schema, alterações que afetam dados em produção
- **Falsos negativos:** o que o script *não* detectou pode ser o problema mais grave

---

## 6. Limitações identificadas

### Falsos positivos observados

Durante o desenvolvimento deste lab, o script gerou falsos positivos ao analisar o próprio arquivo `ai-review.js`:

- A string `'Uso de eval() - risco de code injection'` acionou o padrão de `eval()`, pois a regex encontrou `eval(` dentro do texto da mensagem
- As strings `'Binding em 0.0.0.0'` acionaram o padrão de binding
- Comentários `TODO` nas mensagens dos padrões acionaram o padrão de TODO

**Mitigação aplicada:** o script passou a ignorar linhas que começam com `pattern:` ou `message:`, reduzindo falsos positivos de definições de regras.

### Outras limitações

| Limitação | Impacto |
|-----------|---------|
| **Contexto limitado** | Analisa linha por linha sem entender o contexto ao redor — uma variável chamada `token` pode ser legítima |
| **Diff acumulado** | Analisa todas as mudanças da branch, não só o último commit — arquivos já corrigidos podem reaparecer |
| **Sem análise semântica** | Não entende tipos, fluxo de dados ou escopo de variáveis |
| **Regex não é parser** | Código ofuscado ou quebrado em múltiplas linhas pode escapar da detecção |
| **Sem histórico** | Não compara com versões anteriores para avaliar se o problema já existia |
| **Credenciais do Lab** | O workflow não pode rodar automaticamente com as credenciais AWS do Learner Lab por serem temporárias |
