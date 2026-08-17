# Aula 01 — Fundamentos de Git e Docker

## O que aprendi

- Git: Aprendi a importância do versionamento de código, pois o Git permite acompanhar as alterações realizadas no projeto e manter um histórico das versões. Também aprendi que é possível trabalhar com branches, permitindo que diferentes desenvolvedores trabalhem em funcionalidades distintas sem interferir diretamente no código principal. Além disso, o Git facilita a colaboração entre a equipe, permitindo compartilhar e integrar as alterações realizadas por cada desenvolvedor.
- Docker: Aprendi que o Docker é importante para a padronização dos ambientes de desenvolvimento, pois permite que todos os desenvolvedores utilizem as mesmas configurações e dependências. Dessa forma, reduz problemas relacionados a diferenças entre as máquinas, evitando situações em que o código funciona na máquina de um desenvolvedor, mas não funciona na de outro. Também aprendi que os containers permitem executar aplicações de forma isolada, facilitando a configuração e a execução dos projetos.

## Comandos Git praticados

- [Liste os comandos Git que utilizou]

## Comandos Docker praticados

- docker build -t portfolio-aula01:1.0 .
docker run -d -p 3000:3000 portfolio-aula01:1.0

## Como executar este container

```bash
cd aula-01/app
docker build -t portfolio-aula01:1.0 .
docker run -d -p 3000:3000 portfolio-aula01:1.0
curl http://localhost:3000