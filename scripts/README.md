# Scripts de Automação - GraphQL Microservice

Scripts shell para automação de tarefas do workspace GraphQL Microservice.

## 📄 Scripts Disponíveis

### 🔧 `setup.sh` - Setup Inicial
Configura o ambiente completo para desenvolvimento.

```bash
./scripts/setup.sh
```

**O que faz:**
- ✅ Verifica dependências (Node.js, pnpm)
- ✅ Instala dependências dos projetos
- ✅ Cria arquivos .env a partir dos exemplos
- ✅ Executa verificações de tipo
- ✅ Testa conectividade com MongoDB
- ✅ Verifica Google Cloud CLI
- ✅ Cria diretórios necessários

### 🚀 `dev.sh` - Desenvolvimento
Executa ambos os projetos em modo de desenvolvimento.

```bash
./scripts/dev.sh
```

**O que faz:**
- 🔄 Inicia Core (GraphQL API) na porta 4000
- 🔄 Inicia Report Generator em background
- 📄 Gera logs em `logs/core.log` e `logs/report-generator.log`
- 🔍 Monitora processos e exibe logs em tempo real
- 🛑 Permite parar ambos os serviços com Ctrl+C

**URLs:**
- GraphQL API: http://localhost:4000/graphql

### 🧪 `test.sh` - Testes
Executa testes com múltiplas opções.

```bash
# Uso básico
./scripts/test.sh

# Com opções
./scripts/test.sh [opções]
```

**Opções:**
- `-c, --coverage` - Executar com coverage
- `-w, --watch` - Executar em watch mode
- `-v, --verbose` - Executar em modo verbose
- `-p, --project <nome>` - Executar para projeto específico (core|report-generator)

**Exemplos:**
```bash
./scripts/test.sh --coverage           # Todos os testes com coverage
./scripts/test.sh --project core       # Apenas testes do core
./scripts/test.sh --watch              # Watch mode
./scripts/test.sh -c -p report-generator  # Coverage apenas do report-generator
```

### 🔨 `build.sh` - Build
Compila os projetos TypeScript.

```bash
# Uso básico
./scripts/build.sh

# Com opções
./scripts/build.sh [opções]
```

**Opções:**
- `--clean` - Limpar diretórios de build antes de compilar
- `--production` - Build para ambiente de produção
- `-p, --project <nome>` - Build de projeto específico

**Exemplos:**
```bash
./scripts/build.sh --clean             # Build limpo
./scripts/build.sh --production        # Build de produção
./scripts/build.sh --project core      # Build apenas do core
```

**O que faz:**
- 🔍 Verificação de tipos TypeScript
- 🧹 Linting com ESLint
- 📦 Compilação TypeScript
- 📊 Relatório de tamanho do build

### 🔄 `update.sh` - Atualização
Atualiza repositórios e dependências.

```bash
# Uso básico
./scripts/update.sh

# Com opções
./scripts/update.sh [opções]
```

**Opções:**
- `-d, --deps` - Atualizar dependências para versões mais recentes
- `-f, --force` - Forçar reinstalação (remove node_modules)
- `-p, --project <nome>` - Atualizar projeto específico

**Exemplos:**
```bash
./scripts/update.sh --deps             # Atualizar dependências
./scripts/update.sh --force            # Reinstalação completa
./scripts/update.sh --project core     # Atualizar apenas core
```

**O que faz:**
- 📥 Git pull dos repositórios
- 📦 Atualização/instalação de dependências
- 🔒 Auditoria de segurança
- ✅ Verificação de tipos e testes
- 📊 Relatório de pacotes desatualizados

## 🎯 Fluxos de Trabalho Recomendados

### Setup Inicial
```bash
git clone <repository-url>
cd graphql-microservice
./scripts/setup.sh
```

### Desenvolvimento Diário
```bash
# Iniciar desenvolvimento
./scripts/dev.sh

# Em outro terminal - executar testes
./scripts/test.sh --watch

# Em outro terminal - verificar logs
tail -f logs/core.log
```

### Antes de Commit
```bash
# Verificar código
./scripts/test.sh
./scripts/build.sh

# Ou usando make
make quick-test
```

### Atualização Semanal
```bash
./scripts/update.sh --deps
./scripts/test.sh
```

## 🔧 Troubleshooting

### Permissões de Execução
Se os scripts não executarem:
```bash
chmod +x scripts/*.sh
```

### Verificar Logs
```bash
# Logs dos serviços
tail -f logs/core.log
tail -f logs/report-generator.log

# Logs dos scripts (se existirem)
ls -la scripts/*.log
```

### Problemas Comuns

#### Script não encontrado
```bash
# Verificar se está no diretório correto
pwd  # Deve mostrar .../graphql-microservice

# Verificar se o script existe
ls -la scripts/
```

#### Erro de dependências
```bash
# Limpar e reinstalar
rm -rf core/node_modules report-generator/node_modules
./scripts/setup.sh
```

#### Ports em uso
```bash
# Verificar processos na porta 4000
lsof -i :4000

# Matar processo se necessário
kill <PID>
```

## 📝 Logs

Os scripts geram logs em:
- `logs/core.log` - Logs do serviço Core
- `logs/report-generator.log` - Logs do Report Generator
- `scripts/*.log` - Logs dos próprios scripts (se houver erros)

## 🚀 Integração com IDEs

### VS Code
Adicione tasks no `.vscode/tasks.json`:
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Setup",
      "type": "shell",
      "command": "./scripts/setup.sh",
      "group": "build"
    },
    {
      "label": "Dev",
      "type": "shell",
      "command": "./scripts/dev.sh",
      "group": "build"
    }
  ]
}
```

### Makefile Integration
Todos os scripts também estão disponíveis via `make`:
```bash
make setup    # = ./scripts/setup.sh
make dev      # = ./scripts/dev.sh
make test     # = ./scripts/test.sh
make build    # = ./scripts/build.sh
make update   # = ./scripts/update.sh
```