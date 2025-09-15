# GraphQL Microservice Setup Guide

## 📋 Visão Geral da Arquitetura

Baseado no diagrama, implementaremos uma **arquitetura de microserviços independentes** que se comunicam via **Google Cloud Pub/Sub**:

### Projetos Independentes
- **Core**: Projeto com API GraphQL (publica/consome eventos via Pub/Sub)
- **Report Generator**: Projeto de processamento e integração com IMDb

### Sistema de Comunicação
- **Google Cloud Pub/Sub**: Sistema central de mensageria
- **Comunicação Assíncrona**: Event-driven architecture
- **Desacoplamento**: Cada serviço opera independentemente

### Banco de Dados
- **MongoDB**: Banco principal (conectado via Mongoose)
- **ImDb**: Fonte externa de dados de filmes

---

## 🚀 Setup Inicial

### 1. Corrigindo Dependências

Primeiro, vamos corrigir os problemas identificados no seu setup atual:

```bash
# Remover dependência depreciada
pnpm remove express-graphql

# Instalar substituto moderno
pnpm add graphql-http

# Adicionar dependências essenciais
pnpm add dotenv mongoose @apollo/server @google-cloud/pubsub uuid axios
pnpm add -D @types/node ts-node eslint prettier @typescript-eslint/eslint-plugin @typescript-eslint/parser @types/uuid concurrently
```

### 2. Configuração TypeScript

Criar `tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### 3. Estrutura de Pastas

```
graphql-microservice/           # Workspace
├── docs/
│   ├── DETAILED_SETUP.md       # Este arquivo
│   ├── ARCHITECTURE.md         # Documentação da arquitetura
│   └── diagram-export-*.png    # Diagramas
├── setup.md                    # Setup principal
├── core/                       # 🔵 PROJETO 1 (repositório independente)
│   ├── .git/                   # Próprio controle de versão
│   ├── src/
│   │   ├── graphql/            # Schema e resolvers GraphQL
│   │   ├── database/           # Models e conexão MongoDB
│   │   ├── pubsub/             # Publishers e subscribers
│   │   ├── services/           # Lógica de negócio
│   │   └── utils/              # Utilitários
│   ├── package.json            # Dependências próprias
│   ├── tsconfig.json
│   ├── .env.example
│   └── README.md
└── report-generator/           # 🟢 PROJETO 2 (repositório independente)
    ├── .git/                   # Próprio controle de versão
    ├── src/
    │   ├── services/           # Integração IMDb, geração relatórios
    │   ├── pubsub/             # Publishers e subscribers
    │   ├── generators/         # Geradores CSV/XLSX
    │   ├── types/              # Definições de tipos
    │   └── utils/              # Utilitários
    ├── package.json            # Dependências próprias
    ├── tsconfig.json
    ├── .env.example
    └── README.md
```

### 4. Scripts dos Projetos

Cada projeto tem seus próprios scripts no respectivo `package.json`:

**Core (core/package.json)**:
```json
{
  "scripts": {
    "dev": "nodemon src/index.ts",
    "build": "tsc", 
    "start": "node dist/index.js",
    "lint": "eslint src/**/*.ts",
    "test": "jest",
    "type-check": "tsc --noEmit"
  }
}
```

**Report Generator (report-generator/package.json)**:
```json
{
  "scripts": {
    "dev": "nodemon src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js", 
    "lint": "eslint src/**/*.ts",
    "test": "jest",
    "generate:sample": "ts-node scripts/generate-sample.ts"
  }
}
```

---

---

## ☁️ Configuração Google Cloud Pub/Sub

### 1. Setup do Projeto GCP

```bash
# Instalar Google Cloud CLI (se não tiver)
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Fazer login e configurar projeto
gcloud auth login
gcloud config set project SEU_PROJECT_ID

# Criar service account para o projeto
gcloud iam service-accounts create graphql-microservice \
    --description="Service account for GraphQL microservice" \
    --display-name="GraphQL Microservice"

# Dar permissões de Pub/Sub
gcloud projects add-iam-policy-binding SEU_PROJECT_ID \
    --member="serviceAccount:graphql-microservice@SEU_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/pubsub.editor"

# Baixar chave do service account
gcloud iam service-accounts keys create ./gcp-service-account.json \
    --iam-account=graphql-microservice@SEU_PROJECT_ID.iam.gserviceaccount.com
```

### 2. Criar Tópicos e Subscriptions

```bash
# Criar tópicos
gcloud pubsub topics create report-requests
gcloud pubsub topics create report-completed  
gcloud pubsub topics create imdb-data-requests
gcloud pubsub topics create processing-status

# Criar subscriptions
gcloud pubsub subscriptions create report-requests-sub --topic=report-requests
gcloud pubsub subscriptions create report-completed-sub --topic=report-completed
gcloud pubsub subscriptions create imdb-data-requests-sub --topic=imdb-data-requests
gcloud pubsub subscriptions create processing-status-sub --topic=processing-status
```

### 3. Configuração de Ambiente

Atualizar `.env.example`:

```env
# Google Cloud Pub/Sub
GOOGLE_CLOUD_PROJECT_ID=seu-project-id
GOOGLE_APPLICATION_CREDENTIALS=./gcp-service-account.json

# Tópicos Pub/Sub
TOPIC_REPORT_REQUESTS=report-requests
TOPIC_REPORT_COMPLETED=report-completed
TOPIC_IMDB_DATA_REQUESTS=imdb-data-requests
TOPIC_PROCESSING_STATUS=processing-status

# Database
MONGODB_URL=mongodb://localhost:27017/graphql-microservice

# Servers
MAIN_SERVER_PORT=4000
PROCESSING_PORT=4001
EXTERNAL_SERVER_PORT=4002

# External APIs
IMDB_API_KEY=your_imdb_api_key
IMDB_BASE_URL=https://api.imdb.com
```

---

## 🏗️ Implementação dos Microserviços

### 1. Shared Pub/Sub Configuration

**src/shared/pubsub/client.ts**:
```typescript
import { PubSub } from '@google-cloud/pubsub';

export const pubSubClient = new PubSub({
  projectId: process.env.GOOGLE_CLOUD_PROJECT_ID,
  keyFilename: process.env.GOOGLE_APPLICATION_CREDENTIALS,
});

export const TOPICS = {
  REPORT_REQUESTS: process.env.TOPIC_REPORT_REQUESTS || 'report-requests',
  REPORT_COMPLETED: process.env.TOPIC_REPORT_COMPLETED || 'report-completed',
  IMDB_DATA_REQUESTS: process.env.TOPIC_IMDB_DATA_REQUESTS || 'imdb-data-requests',
  PROCESSING_STATUS: process.env.TOPIC_PROCESSING_STATUS || 'processing-status',
};

export const SUBSCRIPTIONS = {
  REPORT_REQUESTS: 'report-requests-sub',
  REPORT_COMPLETED: 'report-completed-sub',
  IMDB_DATA_REQUESTS: 'imdb-data-requests-sub',
  PROCESSING_STATUS: 'processing-status-sub',
};
```

**src/shared/events/types.ts**:
```typescript
export interface ReportRequestEvent {
  id: string;
  type: 'movie-analysis' | 'trend-report' | 'user-stats';
  movieId?: string;
  userId?: string;
  parameters: Record<string, any>;
  requestedBy: string;
  timestamp: string;
}

export interface ReportCompletedEvent {
  id: string;
  reportId: string;
  status: 'completed' | 'failed';
  data?: any;
  error?: string;
  timestamp: string;
}

export interface ImdbDataRequestEvent {
  id: string;
  movieId: string;
  requestedBy: string;
  timestamp: string;
}

export interface ProcessingStatusEvent {
  id: string;
  status: 'started' | 'processing' | 'completed' | 'failed';
  progress?: number;
  message?: string;
  timestamp: string;
}
```

### 2. Main Server (GraphQL Microservice)

**src/services/main-server/index.ts**:
```typescript
import express from 'express';
import { createHandler } from 'graphql-http/lib/use/express';
import { buildSchema } from 'graphql';
import { connectDatabase } from '../../shared/database/connection';
import { ReportRequestPublisher } from './publishers/report-request-publisher';
import { ReportCompletedSubscriber } from './subscribers/report-completed-subscriber';
import { ProcessingStatusSubscriber } from './subscribers/processing-status-subscriber';

const schema = buildSchema(`
  type Query {
    hello: String
    reports: [Report]
  }

  type Mutation {
    requestReport(input: ReportRequestInput!): ReportRequestResponse!
  }

  type Report {
    id: ID!
    title: String!
    data: String!
    status: String!
    createdAt: String!
  }

  input ReportRequestInput {
    type: String!
    movieId: String
    userId: String
    parameters: String
  }

  type ReportRequestResponse {
    id: ID!
    status: String!
    message: String!
  }

  type Subscription {
    reportStatusUpdated: Report
  }
`);

const resolvers = {
  hello: () => 'Hello from Main GraphQL Server!',
  reports: async () => {
    // Buscar relatórios do banco MongoDB
    return [];
  },
  requestReport: async (args: any) => {
    const publisher = new ReportRequestPublisher();
    const result = await publisher.publishReportRequest(args.input);
    return result;
  }
};

async function startServer() {
  await connectDatabase();
  
  // Iniciar subscribers
  const reportCompletedSubscriber = new ReportCompletedSubscriber();
  const processingStatusSubscriber = new ProcessingStatusSubscriber();
  
  await reportCompletedSubscriber.start();
  await processingStatusSubscriber.start();
  
  const app = express();
  const PORT = process.env.MAIN_SERVER_PORT || 4000;

  app.all('/graphql', createHandler({
    schema,
    rootValue: resolvers,
  }));

  app.listen(PORT, () => {
    console.log(`🚀 Main GraphQL Server running on http://localhost:${PORT}/graphql`);
  });
}

startServer().catch(console.error);
```

**src/services/main-server/publishers/report-request-publisher.ts**:
```typescript
import { v4 as uuidv4 } from 'uuid';
import { pubSubClient, TOPICS } from '../../../shared/pubsub/client';
import { ReportRequestEvent } from '../../../shared/events/types';

export class ReportRequestPublisher {
  private topic = pubSubClient.topic(TOPICS.REPORT_REQUESTS);

  async publishReportRequest(input: any): Promise<any> {
    const event: ReportRequestEvent = {
      id: uuidv4(),
      type: input.type,
      movieId: input.movieId,
      userId: input.userId,
      parameters: input.parameters ? JSON.parse(input.parameters) : {},
      requestedBy: 'main-server',
      timestamp: new Date().toISOString(),
    };

    try {
      const messageId = await this.topic.publishMessage({
        data: Buffer.from(JSON.stringify(event)),
        attributes: {
          eventType: 'ReportRequest',
          version: '1.0',
        },
      });

      console.log(`📤 Published report request: ${messageId}`);
      
      return {
        id: event.id,
        status: 'REQUESTED',
        message: 'Report request sent for processing'
      };
    } catch (error) {
      console.error('❌ Error publishing report request:', error);
      throw new Error('Failed to request report');
    }
  }
}
```

**src/services/main-server/subscribers/report-completed-subscriber.ts**:
```typescript
import { pubSubClient, SUBSCRIPTIONS } from '../../../shared/pubsub/client';
import { ReportCompletedEvent } from '../../../shared/events/types';

export class ReportCompletedSubscriber {
  private subscription = pubSubClient.subscription(SUBSCRIPTIONS.REPORT_COMPLETED);

  async start() {
    console.log('📥 Starting Report Completed Subscriber...');
    
    this.subscription.on('message', this.handleMessage.bind(this));
    this.subscription.on('error', this.handleError.bind(this));
  }

  private async handleMessage(message: any) {
    try {
      const data = JSON.parse(message.data.toString());
      const event: ReportCompletedEvent = data;
      
      console.log(`📬 Received report completed: ${event.reportId}`);
      
      // Processar evento - salvar no MongoDB, notificar usuários, etc.
      await this.processReportCompleted(event);
      
      message.ack();
    } catch (error) {
      console.error('❌ Error processing report completed message:', error);
      message.nack();
    }
  }

  private async processReportCompleted(event: ReportCompletedEvent) {
    // Implementar lógica:
    // 1. Atualizar status do relatório no MongoDB
    // 2. Enviar notificação via WebSocket/SSE
    // 3. Disparar outros eventos se necessário
    console.log(`✅ Processing completed report: ${event.reportId}`);
  }

  private handleError(error: Error) {
    console.error('❌ Report Completed Subscriber error:', error);
  }
}
```

### 3. Processing Service

**src/services/processing/index.ts**:
```typescript
import { ReportRequestSubscriber } from './subscribers/report-request-subscriber';
import { ImdbDataRequestSubscriber } from './subscribers/imdb-data-request-subscriber';

async function startProcessingService() {
  console.log('🔄 Starting Processing Service...');
  
  // Iniciar subscribers
  const reportRequestSubscriber = new ReportRequestSubscriber();
  const imdbDataRequestSubscriber = new ImdbDataRequestSubscriber();
  
  await reportRequestSubscriber.start();
  await imdbDataRequestSubscriber.start();
  
  console.log('📊 Processing Service is running');
  
  // Manter processo vivo
  process.on('SIGINT', async () => {
    console.log('🛑 Shutting down Processing Service...');
    await reportRequestSubscriber.stop();
    await imdbDataRequestSubscriber.stop();
    process.exit(0);
  });
}

startProcessingService().catch(console.error);
```

**src/services/processing/subscribers/report-request-subscriber.ts**:
```typescript
import { pubSubClient, SUBSCRIPTIONS, TOPICS } from '../../../shared/pubsub/client';
import { ReportRequestEvent, ReportCompletedEvent, ProcessingStatusEvent } from '../../../shared/events/types';
import { generateReport } from '../report-generator/generator';
import { v4 as uuidv4 } from 'uuid';

export class ReportRequestSubscriber {
  private subscription = pubSubClient.subscription(SUBSCRIPTIONS.REPORT_REQUESTS);
  private reportCompletedTopic = pubSubClient.topic(TOPICS.REPORT_COMPLETED);
  private processingStatusTopic = pubSubClient.topic(TOPICS.PROCESSING_STATUS);

  async start() {
    console.log('📥 Starting Report Request Subscriber...');
    
    this.subscription.on('message', this.handleMessage.bind(this));
    this.subscription.on('error', this.handleError.bind(this));
  }

  async stop() {
    await this.subscription.close();
  }

  private async handleMessage(message: any) {
    try {
      const data = JSON.parse(message.data.toString());
      const event: ReportRequestEvent = data;
      
      console.log(`📬 Received report request: ${event.id}`);
      
      // Publicar status de início
      await this.publishProcessingStatus(event.id, 'started');
      
      // Processar relatório
      const report = await generateReport(event);
      
      // Publicar relatório concluído
      await this.publishReportCompleted(event.id, report);
      
      message.ack();
    } catch (error) {
      console.error('❌ Error processing report request:', error);
      
      // Publicar status de erro
      const data = JSON.parse(message.data.toString());
      await this.publishProcessingStatus(data.id, 'failed', error.message);
      
      message.nack();
    }
  }

  private async publishProcessingStatus(requestId: string, status: string, message?: string) {
    const statusEvent: ProcessingStatusEvent = {
      id: uuidv4(),
      status: status as any,
      message,
      timestamp: new Date().toISOString(),
    };

    await this.processingStatusTopic.publishMessage({
      data: Buffer.from(JSON.stringify(statusEvent)),
      attributes: {
        eventType: 'ProcessingStatus',
        requestId,
      },
    });
  }

  private async publishReportCompleted(requestId: string, reportData: any) {
    const completedEvent: ReportCompletedEvent = {
      id: uuidv4(),
      reportId: requestId,
      status: 'completed',
      data: reportData,
      timestamp: new Date().toISOString(),
    };

    await this.reportCompletedTopic.publishMessage({
      data: Buffer.from(JSON.stringify(completedEvent)),
      attributes: {
        eventType: 'ReportCompleted',
        requestId,
      },
    });

    console.log(`📤 Published report completed: ${requestId}`);
  }

  private handleError(error: Error) {
    console.error('❌ Report Request Subscriber error:', error);
  }
}
```

**src/services/processing/report-generator/generator.ts**:
```typescript
import { ReportRequestEvent } from '../../../shared/events/types';

export async function generateReport(event: ReportRequestEvent): Promise<any> {
  console.log(`🔄 Generating report for ${event.type}...`);
  
  // Simular processamento
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  switch (event.type) {
    case 'movie-analysis':
      return await generateMovieAnalysis(event.movieId!);
    case 'trend-report':
      return await generateTrendReport();
    case 'user-stats':
      return await generateUserStats(event.userId!);
    default:
      throw new Error(`Unknown report type: ${event.type}`);
  }
}

async function generateMovieAnalysis(movieId: string) {
  // Aqui integraria com External Server para buscar dados do ImDb
  return {
    type: 'movie-analysis',
    movieId,
    analysis: {
      rating: 8.5,
      reviews: 1250,
      genre: 'Action',
      popularity: 'High'
    },
    generatedAt: new Date().toISOString()
  };
}

async function generateTrendReport() {
  return {
    type: 'trend-report',
    trends: [
      { genre: 'Sci-Fi', growth: '+15%' },
      { genre: 'Horror', growth: '+8%' },
      { genre: 'Comedy', growth: '-2%' }
    ],
    generatedAt: new Date().toISOString()
  };
}

async function generateUserStats(userId: string) {
  return {
    type: 'user-stats',
    userId,
    stats: {
      moviesWatched: 45,
      favoriteGenre: 'Drama',
      avgRating: 4.2
    },
    generatedAt: new Date().toISOString()
  };
}
```

### 4. External Server (ImDb Integration)

**src/services/external-server/index.ts**:
```typescript
import { ImdbDataRequestSubscriber } from './subscribers/imdb-data-request-subscriber';

async function startExternalServer() {
  console.log('🎬 Starting External Server (ImDb)...');
  
  // Iniciar subscriber para requisições de dados ImDb
  const imdbDataRequestSubscriber = new ImdbDataRequestSubscriber();
  await imdbDataRequestSubscriber.start();
  
  console.log('🎬 External Server (ImDb) is running');
  
  // Manter processo vivo
  process.on('SIGINT', async () => {
    console.log('🛑 Shutting down External Server...');
    await imdbDataRequestSubscriber.stop();
    process.exit(0);
  });
}

startExternalServer().catch(console.error);
```

**src/services/external-server/subscribers/imdb-data-request-subscriber.ts**:
```typescript
import { pubSubClient, SUBSCRIPTIONS, TOPICS } from '../../../shared/pubsub/client';
import { ImdbDataRequestEvent } from '../../../shared/events/types';
import { fetchImdbData } from '../services/imdb-service';

export class ImdbDataRequestSubscriber {
  private subscription = pubSubClient.subscription(SUBSCRIPTIONS.IMDB_DATA_REQUESTS);
  private processingStatusTopic = pubSubClient.topic(TOPICS.PROCESSING_STATUS);

  async start() {
    console.log('📥 Starting ImDb Data Request Subscriber...');
    
    this.subscription.on('message', this.handleMessage.bind(this));
    this.subscription.on('error', this.handleError.bind(this));
  }

  async stop() {
    await this.subscription.close();
  }

  private async handleMessage(message: any) {
    try {
      const data = JSON.parse(message.data.toString());
      const event: ImdbDataRequestEvent = data;
      
      console.log(`📬 Received ImDb data request: ${event.movieId}`);
      
      // Buscar dados do ImDb
      const imdbData = await fetchImdbData(event.movieId);
      
      // Publicar dados obtidos (pode ser via tópico específico ou salvar no banco)
      console.log(`✅ ImDb data fetched for movie: ${event.movieId}`);
      
      message.ack();
    } catch (error) {
      console.error('❌ Error processing ImDb data request:', error);
      message.nack();
    }
  }

  private handleError(error: Error) {
    console.error('❌ ImDb Data Request Subscriber error:', error);
  }
}
```

**src/services/external-server/services/imdb-service.ts**:
```typescript
import axios from 'axios';

interface ImDbResponse {
  id: string;
  title: string;
  year: string;
  rating: number;
  genre: string[];
  director: string;
  plot: string;
}

export async function fetchImdbData(movieId: string): Promise<ImDbResponse> {
  const apiKey = process.env.IMDB_API_KEY;
  const baseUrl = process.env.IMDB_BASE_URL;
  
  if (!apiKey || !baseUrl) {
    // Simular dados quando não há API configurada
    return {
      id: movieId,
      title: `Movie ${movieId}`,
      year: '2024',
      rating: 8.5,
      genre: ['Action', 'Drama'],
      director: 'Director Name',
      plot: 'A fascinating story about...'
    };
  }
  
  try {
    // Fazer requisição real para API ImDb
    const response = await axios.get(`${baseUrl}/movie/${movieId}`, {
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      timeout: 10000
    });
    
    return response.data;
  } catch (error) {
    console.error(`❌ Error fetching ImDb data for ${movieId}:`, error);
    throw new Error(`Failed to fetch ImDb data for movie: ${movieId}`);
  }
}
```

### 5. Shared Database Models

**src/shared/database/connection.ts**:
```typescript
import mongoose from 'mongoose';

export async function connectDatabase() {
  try {
    const mongoUrl = process.env.MONGODB_URL || 'mongodb://localhost:27017/graphql-microservice';
    await mongoose.connect(mongoUrl);
    console.log('📦 Connected to MongoDB');
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  }
}
```

**src/shared/database/models/Report.ts**:
```typescript
import mongoose, { Schema, Document } from 'mongoose';

export interface IReport extends Document {
  id: string;
  type: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  data?: any;
  error?: string;
  requestedBy: string;
  createdAt: Date;
  updatedAt: Date;
}

const ReportSchema: Schema = new Schema({
  type: { type: String, required: true },
  status: { 
    type: String, 
    enum: ['pending', 'processing', 'completed', 'failed'],
    default: 'pending'
  },
  data: { type: Schema.Types.Mixed },
  error: { type: String },
  requestedBy: { type: String, required: true },
}, {
  timestamps: true,
});

export const Report = mongoose.model<IReport>('Report', ReportSchema);
```

**src/shared/database/models/MovieData.ts**:
```typescript
import mongoose, { Schema, Document } from 'mongoose';

export interface IMovieData extends Document {
  imdbId: string;
  title: string;
  year: string;
  rating: number;
  genre: string[];
  director: string;
  plot: string;
  lastUpdated: Date;
}

const MovieDataSchema: Schema = new Schema({
  imdbId: { type: String, required: true, unique: true },
  title: { type: String, required: true },
  year: { type: String, required: true },
  rating: { type: Number },
  genre: [{ type: String }],
  director: { type: String },
  plot: { type: String },
  lastUpdated: { type: Date, default: Date.now },
});

export const MovieData = mongoose.model<IMovieData>('MovieData', MovieDataSchema);
```

---

## 🔧 Configuração de Ambiente

### .env.example
```env
# Database
MONGODB_URL=mongodb://localhost:27017/graphql-microservice

# Servers
MAIN_SERVER_PORT=4000
PROCESSING_PORT=4001
EXTERNAL_SERVER_PORT=4002

# External APIs
IMDB_API_KEY=your_imdb_api_key
IMDB_BASE_URL=https://api.imdb.com

# Redis (para PubSub em produção)
REDIS_URL=redis://localhost:6379
```

### .gitignore
```gitignore
node_modules/
dist/
.env
*.log
.DS_Store
coverage/
```

---

## 🚦 Como Executar

### Desenvolvimento Local

1. **Instalar dependências**:
```bash
pnpm install
```

2. **Configurar ambiente**:
```bash
cp .env.example .env
# Editar .env com suas configurações
```

3. **Executar serviços**:

**Opção A - Todos os serviços juntos**:
```bash
pnpm dev:all
```

**Opção B - Em terminais separados**:
```bash
# Terminal 1 - Main Server
pnpm dev:main

# Terminal 2 - Processing Service
pnpm dev:processing

# Terminal 3 - External Server
pnpm dev:external
```

### Testando a Integração

1. **Acessar GraphQL Playground**: http://localhost:4000/graphql

2. **Testar query básica**:
```graphql
query {
  hello
  reports {
    id
    status
    createdAt
  }
}
```

3. **Solicitar geração de relatório**:
```graphql
mutation {
  requestReport(input: {
    type: "movie-analysis"
    movieId: "tt1234567"
    parameters: "{\"includeReviews\": true}"
  }) {
    id
    status
    message
  }
}
```

4. **Verificar logs** dos microserviços para acompanhar o fluxo de eventos via Pub/Sub.

---

## 📈 Próximos Passos

### 1. Implementar Autenticação
- JWT tokens
- GraphQL middleware para auth
- Rate limiting

### 2. Monitoramento
- Logs estruturados
- Métricas com Prometheus
- Health checks

### 3. Testes
- Unit tests com Jest
- Integration tests
- E2E tests

### 4. Deploy com Docker

**Dockerfile para cada microserviço**:

**Dockerfile.main-server**:
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
COPY pnpm-lock.yaml ./
RUN npm install -g pnpm && pnpm install

COPY . .
RUN pnpm build

EXPOSE 4000

CMD ["node", "dist/services/main-server/index.js"]
```

**docker-compose.yml**:
```yaml
version: '3.8'

services:
  main-server:
    build:
      context: .
      dockerfile: Dockerfile.main-server
    ports:
      - "4000:4000"
    environment:
      - MONGODB_URL=mongodb://mongo:27017/graphql-microservice
      - GOOGLE_CLOUD_PROJECT_ID=${GOOGLE_CLOUD_PROJECT_ID}
      - GOOGLE_APPLICATION_CREDENTIALS=/app/gcp-service-account.json
    volumes:
      - ./gcp-service-account.json:/app/gcp-service-account.json
    depends_on:
      - mongo

  processing-service:
    build:
      context: .
      dockerfile: Dockerfile.processing
    environment:
      - GOOGLE_CLOUD_PROJECT_ID=${GOOGLE_CLOUD_PROJECT_ID}
      - GOOGLE_APPLICATION_CREDENTIALS=/app/gcp-service-account.json
    volumes:
      - ./gcp-service-account.json:/app/gcp-service-account.json

  external-server:
    build:
      context: .
      dockerfile: Dockerfile.external
    environment:
      - GOOGLE_CLOUD_PROJECT_ID=${GOOGLE_CLOUD_PROJECT_ID}
      - GOOGLE_APPLICATION_CREDENTIALS=/app/gcp-service-account.json
      - IMDB_API_KEY=${IMDB_API_KEY}
    volumes:
      - ./gcp-service-account.json:/app/gcp-service-account.json

  mongo:
    image: mongo:6
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db

volumes:
  mongo_data:
```

**Scripts de deploy**:
```bash
# Build e deploy local
docker-compose up --build

# Deploy em produção (GCP Cloud Run)
gcloud run deploy main-server --source .
gcloud run deploy processing-service --source .
gcloud run deploy external-server --source .
```

### 5. Melhorias de Performance
- DataLoader para N+1 queries
- Caching com Redis
- GraphQL query complexity analysis

---

## 🛠️ Comandos Úteis

```bash
# Desenvolvimento
pnpm dev:all                    # Executar todos os microserviços
pnpm dev:main                   # Executar apenas Main Server
pnpm dev:processing             # Executar apenas Processing Service
pnpm dev:external               # Executar apenas External Server

# Build e produção
pnpm build                      # Compilar TypeScript
pnpm start:main                 # Executar Main Server compilado
pnpm start:processing           # Executar Processing Service compilado
pnpm start:external             # Executar External Server compilado

# Qualidade de código
pnpm format                     # Formatar código com Prettier
pnpm lint                       # Executar ESLint

# Google Cloud Pub/Sub
pnpm pubsub:setup               # Configurar tópicos e subscriptions
gcloud pubsub topics list       # Listar tópicos
gcloud pubsub subscriptions list # Listar subscriptions

# Docker
docker-compose up --build       # Build e executar com Docker
docker-compose logs -f          # Ver logs de todos os serviços
docker-compose down             # Parar todos os serviços

# Monitoramento
gcloud logging read "resource.type=pubsub_topic" # Logs do Pub/Sub
```

---

## 📚 Recursos Adicionais

- [GraphQL Docs](https://graphql.org/learn/)
- [Google Cloud Pub/Sub](https://cloud.google.com/pubsub/docs)
- [Apollo Server](https://www.apollographql.com/docs/apollo-server/)
- [Mongoose Docs](https://mongoosejs.com/docs/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [Docker Compose](https://docs.docker.com/compose/)

---

## 🎯 Resumo da Arquitetura

Esta documentação implementa uma **arquitetura de microserviços event-driven** usando **Google Cloud Pub/Sub** como sistema central de mensageria:

### ✅ Benefícios desta Arquitetura:
- **Desacoplamento**: Microserviços independentes
- **Escalabilidade**: Cada serviço escala independentemente  
- **Resiliência**: Falhas isoladas não afetam todo o sistema
- **Event-Driven**: Comunicação assíncrona via eventos
- **Flexibilidade**: Fácil adição de novos microserviços

### 🔄 Fluxo de Eventos:
1. **Main Server** recebe requisição GraphQL
2. **Publica evento** no Google Cloud Pub/Sub  
3. **Processing Service** consome evento e processa
4. **External Server** busca dados externos quando necessário
5. **Resultados retornados** via eventos para Main Server
6. **MongoDB** persiste dados de todos os serviços

Este setup te dará uma base sólida e moderna para implementar a arquitetura completa do seu diagrama! 🚀