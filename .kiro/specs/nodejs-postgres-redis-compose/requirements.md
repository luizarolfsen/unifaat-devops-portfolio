# Requirements Document

## Introduction

Este documento define os requisitos para a criação de um `docker-compose.yml` que orquestra três serviços: uma API Node.js 20 com Express, um banco de dados PostgreSQL 15 e um cache Redis 7. O objetivo é garantir que todos os serviços sejam inicializados de forma confiável, com persistência de dados, verificações de saúde, políticas de reinicialização e configuração baseada em variáveis de ambiente provenientes de um arquivo `.env`.

---

## Glossary

- **Compose_File**: O arquivo `docker-compose.yml` que define e orquestra todos os serviços da aplicação.
- **API_Service**: O contêiner da aplicação Node.js 20 com Express exposto na porta 3000.
- **Postgres_Service**: O contêiner do banco de dados PostgreSQL 15.
- **Redis_Service**: O contêiner do cache Redis 7.
- **App_Network**: A rede bridge customizada à qual todos os serviços pertencem.
- **Healthcheck**: Mecanismo do Docker que verifica periodicamente se um serviço está operacional.
- **Named_Volume**: Volume Docker com nome explícito para persistência de dados além do ciclo de vida do contêiner.
- **Env_File**: O arquivo `.env` na raiz do projeto que contém os valores das variáveis de ambiente.
- **Interpolation**: Substituição de variáveis `${VAR:-default}` no `docker-compose.yml` com valores do `Env_File`.

---

## Requirements

### Requirement 1: Serviço da API Node.js

**User Story:** Como desenvolvedor, quero que a API Node.js 20 com Express seja definida no `docker-compose.yml`, para que o serviço suba de forma consistente com todas as suas dependências satisfeitas.

#### Acceptance Criteria

1. THE `Compose_File` SHALL definir um serviço chamado `api` construído a partir de um `Dockerfile` no contexto do diretório atual.
2. THE `API_Service` SHALL expor a porta `3000` do contêiner mapeada para a porta definida por `${APP_PORT:-3000}` no host.
3. THE `API_Service` SHALL receber as variáveis de ambiente `NODE_ENV`, `APP_PORT`, `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `REDIS_HOST` e `REDIS_PORT` via `Interpolation` a partir do `Env_File`.
4. WHEN o `Postgres_Service` e o `Redis_Service` reportarem status `healthy` no `Healthcheck`, THE `API_Service` SHALL iniciar, utilizando `depends_on` com `condition: service_healthy`.
5. THE `API_Service` SHALL pertencer à `App_Network`.
6. THE `API_Service` SHALL ter política de reinicialização `unless-stopped`.
7. THE `API_Service` SHALL ter um `Healthcheck` que executa `wget --quiet --tries=1 --spider http://localhost:3000/health` com intervalo de 30 segundos, timeout de 10 segundos, 3 tentativas e período inicial de 20 segundos.

---

### Requirement 2: Serviço do PostgreSQL

**User Story:** Como desenvolvedor, quero que o PostgreSQL 15 seja definido no `docker-compose.yml` com persistência de dados, para que os dados do banco sobrevivam a reinicializações do contêiner.

#### Acceptance Criteria

1. THE `Compose_File` SHALL definir um serviço chamado `postgres` utilizando a imagem `postgres:15-alpine`.
2. THE `Postgres_Service` SHALL receber as variáveis de ambiente `POSTGRES_DB`, `POSTGRES_USER` e `POSTGRES_PASSWORD` via `Interpolation` a partir do `Env_File`.
3. THE `Postgres_Service` SHALL montar um `Named_Volume` chamado `postgres_data` no caminho `/var/lib/postgresql/data` do contêiner.
4. THE `Postgres_Service` SHALL pertencer à `App_Network`.
5. THE `Postgres_Service` SHALL ter política de reinicialização `unless-stopped`.
6. THE `Postgres_Service` SHALL ter um `Healthcheck` que executa `pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}` com intervalo de 10 segundos, timeout de 5 segundos, 5 tentativas e período inicial de 10 segundos.

---

### Requirement 3: Serviço do Redis

**User Story:** Como desenvolvedor, quero que o Redis 7 seja definido no `docker-compose.yml`, para que o serviço de cache esteja disponível à API com configuração de persistência básica.

#### Acceptance Criteria

1. THE `Compose_File` SHALL definir um serviço chamado `redis` utilizando a imagem `redis:7-alpine`.
2. THE `Redis_Service` SHALL ser iniciado com o comando `redis-server --save 60 1 --loglevel warning` para habilitar persistência periódica e reduzir verbosidade de logs.
3. THE `Redis_Service` SHALL pertencer à `App_Network`.
4. THE `Redis_Service` SHALL ter política de reinicialização `unless-stopped`.
5. THE `Redis_Service` SHALL ter um `Healthcheck` que executa `redis-cli ping` com intervalo de 10 segundos, timeout de 5 segundos, 5 tentativas e período inicial de 5 segundos.

---

### Requirement 4: Rede e Volumes

**User Story:** Como desenvolvedor, quero que todos os serviços compartilhem uma rede bridge customizada e que os volumes nomeados sejam declarados explicitamente, para que a comunicação entre serviços seja isolada e os dados sejam persistidos.

#### Acceptance Criteria

1. THE `Compose_File` SHALL declarar a `App_Network` com o driver `bridge` na seção `networks` de nível superior.
2. THE `Compose_File` SHALL declarar o `Named_Volume` `postgres_data` com o driver `local` na seção `volumes` de nível superior.
3. WHEN dois serviços pertencem à `App_Network`, THE `Compose_File` SHALL permitir que eles se comuniquem usando o nome do serviço como hostname DNS.

---

### Requirement 5: Configuração por Variáveis de Ambiente

**User Story:** Como operador, quero que todas as configurações sensíveis e específicas de ambiente sejam lidas de um arquivo `.env`, para que o `docker-compose.yml` não contenha valores hardcoded.

#### Acceptance Criteria

1. THE `Compose_File` SHALL utilizar `Interpolation` com fallback (`${VAR:-default}`) para todas as variáveis de ambiente passadas aos serviços, de modo que o arquivo funcione mesmo sem o `Env_File` quando valores padrão forem suficientes.
2. IF o `Env_File` não estiver presente, THEN THE `Compose_File` SHALL utilizar os valores padrão definidos na `Interpolation` para as variáveis que os possuam.
3. THE `Env_File` SHALL conter as variáveis: `APP_PORT`, `NODE_ENV`, `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `REDIS_HOST` e `REDIS_PORT`.
