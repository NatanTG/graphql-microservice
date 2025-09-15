# GraphQL Microservice - Sistema de Geração de Relatórios

Workspace que organiza dois microserviços independentes para geração de relatórios de filmes usando GraphQL, MongoDB e comunicação via Google Cloud Pub/Sub.

## 🎯 Visão Geral

Este é um **workspace de estudos** que organiza dois projetos independentes:

### 🔵 Core (Projeto 1)
- **Repositório independente** com API GraphQL
- Recebe solicitações de relatórios via GraphQL
- Gerencia dados no MongoDB com Mongoose
- Publica eventos via Google Cloud Pub/Sub

### 🟢 Report-Generator (Projeto 2) 
- **Repositório independente** de processamento
- Consome eventos via Pub/Sub
- Integra com API do IMDb para buscar dados de filmes
- Gera relatórios em formatos CSV/XLSX

### 🔄 Comunicação
Os dois projetos se comunicam **exclusivamente via Google Cloud Pub/Sub**, mantendo total independência.

## ⚡ Quick Start

### Pré-requisitos
- Node.js 18+
- pnpm (ou npm)
- MongoDB local ou remoto
- Google Cloud Project (para Pub/Sub)

### Instalação

```bash
# 1. Clonar o workspace
git clone <repository-url>
cd graphql-microservice

# 2. Setup automático (recomendado)
make setup
# ou
./scripts/setup.sh

# 3. Configuração manual (se necessário)
# Core (Projeto 1)
cd core
pnpm install
cp .env.example .env
# Editar core/.env com suas configurações

# Report Generator (Projeto 2)  
cd ../report-generator
pnpm install
cp .env.example .env
# Editar report-generator/.env com suas configurações
```

### Execução

```bash
# Modo automático (recomendado) - executa ambos os projetos
make dev
# ou
./scripts/dev.sh

# Modo manual - em terminais separados
# Terminal 1 - Core (GraphQL API)
cd core && pnpm dev

# Terminal 2 - Report Generator (Processamento)
cd report-generator && pnpm dev
```

### Testar a API

Acesse o GraphQL Playground em `http://localhost:4000/graphql` e teste:

```graphql
mutation {
  requestReport(input: {
    type: "movie-analysis"
    movieId: "tt1234567"
  }) {
    id
    status
    message
  }
}
```

## 📁 Estrutura do Workspace

```
graphql-microservice/           # Workspace (projeto pai)
├── setup.md                    # Este arquivo
├── docs/
│   ├── DETAILED_SETUP.md       # Setup técnico completo
│   ├── ARCHITECTURE.md         # Visão arquitetural detalhada
│   └── diagram-export-*.png    # Diagrama da arquitetura
├── core/                       # 🔵 PROJETO 1 (independente)
│   ├── .git/                   # Próprio repositório Git
│   ├── src/                    # Código fonte do Core
│   ├── package.json            # Dependências próprias
│   ├── tsconfig.json           # Configuração TypeScript
│   └── README.md               # Documentação específica
└── report-generator/           # 🟢 PROJETO 2 (independente)
    ├── .git/                   # Próprio repositório Git
    ├── src/                    # Código fonte do Report Generator
    ├── package.json            # Dependências próprias
    ├── tsconfig.json           # Configuração TypeScript
    └── README.md               # Documentação específica
```

**Importante**: Cada projeto tem seu próprio repositório Git, package.json e configurações independentes.

## 🔄 Fluxo de Funcionamento

1. **Cliente** faz uma requisição GraphQL para gerar relatório
2. **Core** publica evento no Google Cloud Pub/Sub
3. **Report-Generator** consome evento e processa:
   - Busca dados na API do IMDb
   - Gera relatório (CSV/XLSX)
   - Publica evento de conclusão
4. **Core** recebe evento de conclusão e salva dados no MongoDB

## 🚀 Comandos Úteis

### 🎯 Comandos Rápidos (Make)
```bash
make help              # Ver todos os comandos disponíveis
make setup             # Setup inicial completo
make dev               # Desenvolvimento (ambos os projetos)
make test              # Executar todos os testes
make test-coverage     # Testes com coverage
make build             # Build de produção
make clean             # Limpar artefatos
make lint              # Verificar código
make format            # Formatar código
```

### 🔧 Scripts de Automação
```bash
# Setup e desenvolvimento
./scripts/setup.sh     # Setup inicial completo
./scripts/dev.sh       # Desenvolvimento com logs
./scripts/update.sh    # Atualizar dependências

# Testes
./scripts/test.sh      # Todos os testes
./scripts/test.sh -c   # Com coverage
./scripts/test.sh -w   # Watch mode
./scripts/test.sh -p core  # Apenas core

# Build
./scripts/build.sh     # Build normal
./scripts/build.sh --clean    # Build limpo
./scripts/build.sh --production  # Build produção
```

### 📦 Comandos do Package.json
```bash
# Desenvolvimento
pnpm dev               # Script que chama ./scripts/dev.sh
pnpm test              # Script que chama ./scripts/test.sh
pnpm build             # Script que chama ./scripts/build.sh

# Por projeto
pnpm test:core         # Testes apenas do core
pnpm test:report-gen   # Testes apenas do report-generator
pnpm build:core        # Build apenas do core
pnpm lint:core         # Lint apenas do core

# Logs
pnpm logs              # Ver logs de ambos os projetos
pnpm logs:core         # Ver logs apenas do core
pnpm logs:report-gen   # Ver logs apenas do report-generator
```

### 🛠️ Comandos Manuais (quando necessário)
```bash
# Por projeto individual
cd core && pnpm dev
cd report-generator && pnpm dev

# Verificações
cd core && pnpm type-check && pnpm lint
cd report-generator && pnpm type-check && pnpm lint
```

## 📚 Documentação Adicional

- [Setup Técnico Detalhado](docs/DETAILED_SETUP.md) - Configuração completa com Google Cloud
- [Arquitetura](docs/ARCHITECTURE.md) - Visão detalhada da arquitetura
- [Core README](core/README.md) - Documentação específica do microserviço Core
- [Report Generator README](report-generator/README.md) - Documentação específica do microserviço Report Generator

## 🛠️ Configuração de Desenvolvimento

### MongoDB Local
```bash
# Usando Docker
docker run -d -p 27017:27017 --name mongodb mongo:6

# Ou instalar localmente
# https://docs.mongodb.com/manual/installation/
```

### Google Cloud Pub/Sub
Para desenvolvimento local, você pode usar o emulador:
```bash
# Instalar Google Cloud CLI
curl https://sdk.cloud.google.com | bash

# Usar emulador para desenvolvimento
gcloud components install pubsub-emulator
gcloud beta emulators pubsub start --project=local-project
```

Consulte [docs/DETAILED_SETUP.md](docs/DETAILED_SETUP.md) para configuração completa em produção.

## 🎯 Próximos Passos

### Para o Core
1. Implementar schema e resolvers GraphQL
2. Configurar conexão MongoDB com Mongoose
3. Implementar publishers/subscribers Pub/Sub
4. Adicionar autenticação e autorização

### Para o Report Generator  
1. Implementar subscribers Pub/Sub
2. Configurar integração com API do IMDb
3. Adicionar geração de arquivos CSV/XLSX
4. Implementar cache para dados do IMDb

### Para o Workspace
1. Configurar Docker Compose para ambos os projetos
2. Implementar testes de integração entre projetos
3. Configurar CI/CD para deploy independente
4. Adicionar monitoramento e logs distribuídos

---

**Nota**: Este é um **workspace de estudos** que organiza dois projetos independentes para aprender arquitetura de microserviços. Cada projeto pode ser desenvolvido, testado e deployado separadamente.