# Análise do Uso de IA — Aula 02 TF

## Prompt Utilizado

> "Crie um docker-compose.yml para uma aplicação Node.js 20 com Express que usa PostgreSQL 15 como banco de dados e Redis 7 como cache. A API roda na porta 3000. O PostgreSQL precisa de volume nomeado para persistência. Todos os serviços devem estar na mesma rede bridge customizada. Use variáveis de ambiente com interpolação de arquivo .env. Adicione healthchecks, depends_on com condition, e restart policy unless-stopped."

---

## Output Original do Kiro

```yaml
services:

  api:
    build:
      context: .
      dockerfile: Dockerfile
    image: unifaat-api:latest
    container_name: unifaat-api
    restart: unless-stopped
    ports:
      - "${APP_PORT:-3000}:3000"
    environment:
      NODE_ENV: ${NODE_ENV:-production}
      APP_PORT: ${APP_PORT:-3000}
      POSTGRES_HOST: ${POSTGRES_HOST}
      POSTGRES_PORT: ${POSTGRES_PORT}
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required and must not be empty}
      REDIS_HOST: ${REDIS_HOST}
      REDIS_PORT: ${REDIS_PORT}
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 20s

  postgres:
    image: postgres:15-alpine
    container_name: unifaat-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required and must not be empty}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

  redis:
    image: redis:7-alpine
    container_name: unifaat-redis
    restart: unless-stopped
    command: redis-server --save 60 1 --loglevel warning
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 5s

volumes:
  postgres_data:
    driver: local

networks:
  app-network:
    driver: bridge
```

---

## Alterações que Fiz Manualmente

| O que mudei | Por quê |
|---|---|
| Criei o arquivo `.env` com as variáveis reais do projeto | O Kiro não gerou o `.env`, só o compose que referencia as variáveis |
| Adicionei `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` no `.env` | O `app.js` usa esses nomes, mas o `.env` inicial só tinha as variáveis `POSTGRES_*` |
| Criei o `.env.example` com os mesmos campos mas senha placeholder | Boa prática: não commitar senhas reais, mas documentar quais variáveis são necessárias |
| Corrigi o nome do arquivo `.dockeringore` para `.dockerignore` | Estava com typo — sem isso, o Docker ignorava o arquivo e copiava `.env` e `node_modules` para dentro da imagem |
| Renomeei a rede de `app-network` para `technova` | Nome mais descritivo e alinhado com o projeto |

## Alterações Aplicadas pelo Kiro Após Análise

| O que o Kiro corrigiu | Por quê |
|---|---|
| Substituiu `APP_PORT`, `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DB` no `environment` do serviço `api` por `PORT`, `DB_HOST`, `DB_PORT`, `DB_NAME` | O `app.js` lê `PORT` e `DB_*`, não `APP_PORT` e `POSTGRES_*` — a API conectaria em `localhost` em vez de `postgres` sem essa correção |
| Adicionou volume `redis_data:/data` no serviço Redis e declarou na seção `volumes` raiz | O Redis usava `--save 60 1` para gravar snapshots RDB, mas sem volume o arquivo sumiria ao recriar o container — persistência ineficaz |
| Adicionou `DB_USER` e `DB_PASSWORD` com `:?` no `environment` do serviço `api` | Variáveis necessárias para autenticação no banco, com falha explícita se ausentes |

---

## O que o Kiro Acertou

- Estrutura completa do `docker-compose.yml` com os três serviços (api, postgres, redis)
- `depends_on` com `condition: service_healthy` em ambas as dependências da API
- `restart: unless-stopped` em todos os serviços
- Healthchecks detalhados com `interval`, `timeout`, `retries` e `start_period` para os três serviços
- `pg_isready` com `$$` para expansão correta dentro do container no healthcheck do Postgres
- Volume nomeado `postgres_data` para persistência do PostgreSQL, declarado na seção raiz
- Rede bridge customizada compartilhada pelos três serviços (gerada como `app-network`, renomeada para `technova` pelo usuário)
- Sintaxe `:?` no `POSTGRES_PASSWORD` para falha explícita com mensagem de erro
- Defaults seguros via `${VAR:-valor}` para variáveis opcionais
- Comando `redis-server --save 60 1 --loglevel warning` correto para persistência mínima do Redis

## O que o Kiro Errou ou Omitiu

- **Nomes de variáveis desalinhados com o `app.js`:** injetou `APP_PORT`, `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DB` no container da API, mas o código lê `PORT`, `DB_HOST`, `DB_PORT`, `DB_NAME` — a API rodaria mas nunca conectaria no banco corretamente
- **Sem volume para o Redis:** o compose usava `--save 60 1` mas não declarava volume para `/data`, tornando a persistência do Redis ineficaz
- **Não gerou o `.env`** nem o `.env.example` — deixou a configuração das variáveis para o usuário sem nenhum template
- **Não identificou o typo no `.dockeringore`** na primeira análise (precisou de revisão explícita para detectar)

---

## Minha Avaliação

- **Tempo economizado usando IA:** ~25 minutos (estrutura base, healthchecks, sintaxe de interpolação)
- **Tempo gasto validando/corrigindo:** ~15 minutos (revisar variáveis, testar alinhamento com app.js, corrigir dockerignore)
- **Nota para o output da IA (1-10):** 7
- **Usaria novamente para este tipo de tarefa?** Sim — o Kiro entregou uma base sólida e funcional para ~80% do trabalho. Os erros encontrados foram de integração com o código existente (nomes de variáveis), não de conhecimento técnico de Docker. Para projetos novos onde a IA gera tudo do zero, o alinhamento seria automático. Para projetos com código pré-existente, é necessário revisar o mapeamento de variáveis entre o compose e a aplicação.
