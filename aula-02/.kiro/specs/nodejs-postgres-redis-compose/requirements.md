# Requirements Document

## Introduction

Este documento descreve os requisitos para a criação de um arquivo `docker-compose.yml` que orquestra uma aplicação Node.js 20 com Express, banco de dados PostgreSQL 15 e cache Redis 7. O objetivo é definir uma configuração de infraestrutura local reproduzível, com persistência de dados, verificação de saúde dos serviços, e isolamento de rede.

## Glossary

- **Compose_File**: O arquivo `docker-compose.yml` que define e orquestra todos os serviços da aplicação.
- **API_Service**: O serviço Docker que executa a aplicação Node.js 20 com Express.
- **Postgres_Service**: O serviço Docker que executa o banco de dados PostgreSQL 15.
- **Redis_Service**: O serviço Docker que executa o servidor de cache Redis 7.
- **App_Network**: A rede bridge customizada que interliga todos os serviços.
- **Env_File**: O arquivo `.env` que contém as variáveis de ambiente utilizadas pelo Compose_File.
- **Named_Volume**: Volume Docker nomeado gerenciado pelo Docker Engine para persistência de dados.
- **Healthcheck**: Verificação periódica executada pelo Docker para determinar se um serviço está operacional.
- **Restart_Policy**: Política que define o comportamento do Docker ao reiniciar um contêiner após falha ou parada.

---

## Requirements

### Requirement 1: Serviço da API Node.js

**User Story:** Como desenvolvedor, quero que a API Node.js 20 com Express seja executada como um serviço Docker, para que a aplicação rode em ambiente isolado e reproduzível.

#### Acceptance Criteria

1. THE Compose_File SHALL definir um serviço chamado `api` baseado em imagem construída a partir do `Dockerfile` localizado no diretório raiz do projeto.
2. THE API_Service SHALL expor a porta `3000` do contêiner mapeada para a porta definida pela variável `APP_PORT` do Env_File (intervalo válido: 1–65535), com valor padrão `3000`.
3. THE API_Service SHALL ter a `restart_policy` configurada como `unless-stopped`.
4. WHEN o Compose_File for iniciado, THE API_Service SHALL receber as variáveis de ambiente `NODE_ENV`, `APP_PORT`, `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `REDIS_HOST` e `REDIS_PORT` interpoladas a partir do Env_File.
5. WHEN o Compose_File for iniciado, THE API_Service SHALL aguardar que o Postgres_Service E o Redis_Service estejam simultaneamente com status `healthy` antes de iniciar, usando `depends_on` com `condition: service_healthy` para ambos os serviços.
6. THE API_Service SHALL estar conectado exclusivamente à App_Network, sendo proibida a conexão a qualquer outra rede, incluindo redes de infraestrutura como monitoramento ou logging.
7. THE API_Service SHALL ter um Healthcheck configurado para verificar o endpoint `http://localhost:3000/health` a cada `30s`, com timeout de `10s`, `3` tentativas e `start_period` de `20s`.
8. IF o Env_File estiver ausente ou contiver variáveis obrigatórias indefinidas ou vazias, THEN THE Compose_File SHALL falhar ao iniciar antes de criar qualquer contêiner, exibindo erro que identifica a variável ausente.
9. WHEN o Healthcheck do API_Service falhar nas 3 tentativas consecutivas, THEN THE API_Service SHALL ter seu status alterado para `unhealthy` sem reinício automático, preservando o contêiner para inspeção de logs.

---

### Requirement 2: Serviço PostgreSQL 15

**User Story:** Como desenvolvedor, quero que o PostgreSQL 15 seja executado como um serviço Docker com persistência de dados, para que os dados da aplicação sobrevivam a reinicializações dos contêineres.

#### Acceptance Criteria

1. THE Compose_File SHALL definir um serviço chamado `postgres` usando a imagem oficial `postgres:15-alpine`.
2. THE Postgres_Service SHALL ter a `restart_policy` configurada como `unless-stopped`.
3. THE Postgres_Service SHALL receber as variáveis de ambiente `POSTGRES_DB`, `POSTGRES_USER` e `POSTGRES_PASSWORD` interpoladas a partir do Env_File; `POSTGRES_DB` e `POSTGRES_USER` devem ter entre 3 e 63 caracteres; `POSTGRES_PASSWORD` deve ter entre 8 e 63 caracteres; nenhuma das três pode ser vazia ou indefinida.
4. THE Postgres_Service SHALL montar um Named_Volume chamado `postgres_data` no caminho `/var/lib/postgresql/data` para garantir a persistência dos dados.
5. THE Postgres_Service SHALL estar conectado à App_Network e não deverá estar conectado a nenhuma rede não declarada no Compose_File.
6. THE Postgres_Service SHALL ter um Healthcheck configurado para verificar a disponibilidade do banco usando `pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}` a cada `10s`, com timeout de `5s`, `5` tentativas e `start_period` de `10s`.
7. WHEN o Healthcheck do Postgres_Service falhar nas 5 tentativas consecutivas, THEN THE Postgres_Service SHALL ter seu status alterado para `unhealthy` com o contêiner mantido em execução para inspeção de logs.
8. THE Compose_File SHALL declarar o Named_Volume `postgres_data` na seção `volumes` de nível raiz com driver `local`.

---

### Requirement 3: Serviço Redis 7

**User Story:** Como desenvolvedor, quero que o Redis 7 seja executado como um serviço Docker de cache, para que a aplicação disponha de um mecanismo de cache em memória confiável.

#### Acceptance Criteria

1. THE Compose_File SHALL definir um serviço chamado `redis` usando a imagem oficial `redis:7-alpine`.
2. THE Redis_Service SHALL ter a `restart_policy` configurada como `unless-stopped`.
3. THE Redis_Service SHALL ser inicializado com o comando `redis-server --save 60 1 --loglevel warning` e ter um volume nomeado montado no diretório de dados do Redis para garantir que os snapshots RDB sejam preservados entre reinicializações do contêiner.
4. THE Redis_Service SHALL estar conectado à App_Network e expor a porta `6379` exclusivamente na App_Network, sem mapeamento para a interface do host; IF o Redis_Service não estiver conectado à App_Network, THEN THE Redis_Service SHALL ter qualquer exposição da porta `6379` proibida.
5. THE Redis_Service SHALL ter um Healthcheck configurado para verificar a disponibilidade usando `redis-cli ping` a cada `10s`, com timeout de `5s`, `5` tentativas e `start_period` de `5s`.

---

### Requirement 4: Rede Bridge Customizada

**User Story:** Como desenvolvedor, quero que todos os serviços estejam em uma rede bridge customizada e isolada, para que a comunicação entre eles seja segura e não conflite com outras redes Docker do host.

#### Acceptance Criteria

1. THE Compose_File SHALL declarar uma rede chamada `app-network` com driver `bridge` e `internal: false` para permitir acesso externo controlado.
2. THE API_Service, THE Postgres_Service e THE Redis_Service SHALL estar todos conectados à App_Network e NÃO deverão estar conectados a nenhuma rede não declarada no Compose_File.
3. WHILE os serviços estiverem em execução, THE App_Network SHALL permitir que o API_Service resolva os hostnames `postgres` e `redis` para se comunicar com os respectivos serviços.
4. IF a criação da App_Network falhar durante o `docker compose up`, THEN THE Compose_File SHALL abortar a inicialização de todos os serviços com mensagem de erro indicando falha na criação da rede.
5. THE App_Network SHALL mapear o hostname de cada serviço ao nome do serviço declarado no Compose_File, garantindo resolução DNS determinística sem uso de aliases.

---

### Requirement 5: Volumes Nomeados

**User Story:** Como desenvolvedor, quero que os volumes nomeados sejam declarados explicitamente no Compose_File, para que o Docker gerencie o ciclo de vida dos dados de forma previsível.

#### Acceptance Criteria

1. THE Compose_File SHALL declarar o Named_Volume `postgres_data` na seção `volumes` de nível raiz com driver `local`.
2. THE Postgres_Service SHALL referenciar o Named_Volume `postgres_data` montado no diretório de dados padrão do PostgreSQL (`/var/lib/postgresql/data`).
3. IF o Named_Volume `postgres_data` não estiver declarado na seção `volumes` de nível raiz do Compose_File, THEN o Compose_File SHALL ser considerado inválido e falhar na validação com uma mensagem de erro indicando volume não declarado.

---

### Requirement 6: Interpolação de Variáveis de Ambiente

**User Story:** Como desenvolvedor, quero que todas as variáveis sensíveis e configuráveis sejam lidas do arquivo `.env`, para que o Compose_File não contenha valores hardcoded e possa ser reutilizado em diferentes ambientes.

#### Acceptance Criteria

1. THE Compose_File SHALL suportar interpolação de variáveis a partir do Env_File (`.env`) localizado no mesmo diretório que o Compose_File.
2. THE Compose_File SHALL definir valor padrão via sintaxe `${APP_PORT:-3000}` para a variável `APP_PORT`, onde o valor padrão deve estar no intervalo `1–65535`.
3. THE Compose_File SHALL definir valor padrão via sintaxe `${NODE_ENV:-production}` para a variável `NODE_ENV`, onde o valor padrão deve ser um dos valores válidos: `development`, `staging` ou `production`.
4. IF a variável `POSTGRES_PASSWORD` não estiver definida no Env_File ou estiver vazia, THEN THE Compose_File SHALL, conjuntamente, falhar ao iniciar sem criar nenhum contêiner E exibir mensagem de erro que identifica explicitamente a variável ausente ou vazia; o requisito é considerado violado se qualquer uma das duas condições não for satisfeita.
