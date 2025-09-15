# GraphQL Microservice Workspace Makefile
# Comandos rápidos para desenvolvimento

.PHONY: help setup dev test build clean lint format type-check update
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
NC := \033[0m

help: ## Show this help message
	@echo "$(BLUE)GraphQL Microservice Workspace$(NC)"
	@echo "================================"
	@echo ""
	@echo "$(GREEN)Available commands:$(NC)"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

setup: ## Setup workspace and install dependencies
	@echo "$(BLUE)Setting up workspace...$(NC)"
	@./scripts/setup.sh

dev: ## Start development environment
	@echo "$(BLUE)Starting development environment...$(NC)"
	@./scripts/dev.sh

test: ## Run all tests
	@echo "$(BLUE)Running tests...$(NC)"
	@./scripts/test.sh

test-coverage: ## Run tests with coverage
	@echo "$(BLUE)Running tests with coverage...$(NC)"
	@./scripts/test.sh --coverage

test-watch: ## Run tests in watch mode
	@echo "$(BLUE)Running tests in watch mode...$(NC)"
	@./scripts/test.sh --watch

test-core: ## Run tests for core project only
	@echo "$(BLUE)Running core tests...$(NC)"
	@./scripts/test.sh --project core

test-report-gen: ## Run tests for report-generator only
	@echo "$(BLUE)Running report-generator tests...$(NC)"
	@./scripts/test.sh --project report-generator

build: ## Build all projects
	@echo "$(BLUE)Building projects...$(NC)"
	@./scripts/build.sh

build-clean: ## Clean build and rebuild
	@echo "$(BLUE)Clean building projects...$(NC)"
	@./scripts/build.sh --clean

build-prod: ## Build for production
	@echo "$(BLUE)Building for production...$(NC)"
	@./scripts/build.sh --production

clean: ## Clean all build artifacts and logs
	@echo "$(BLUE)Cleaning workspace...$(NC)"
	@pnpm clean

lint: ## Run linting on all projects
	@echo "$(BLUE)Running linting...$(NC)"
	@pnpm lint

lint-fix: ## Fix linting issues
	@echo "$(BLUE)Fixing linting issues...$(NC)"
	@pnpm lint:fix

format: ## Format code with prettier
	@echo "$(BLUE)Formatting code...$(NC)"
	@pnpm format

type-check: ## Check TypeScript types
	@echo "$(BLUE)Checking TypeScript types...$(NC)"
	@pnpm type-check

update: ## Update dependencies and repositories
	@echo "$(BLUE)Updating workspace...$(NC)"
	@./scripts/update.sh

update-deps: ## Update dependencies to latest versions
	@echo "$(BLUE)Updating dependencies...$(NC)"
	@./scripts/update.sh --deps

logs: ## Show logs from all services
	@echo "$(BLUE)Showing logs...$(NC)"
	@pnpm logs

logs-core: ## Show logs from core service
	@echo "$(BLUE)Showing core logs...$(NC)"
	@pnpm logs:core

logs-report-gen: ## Show logs from report-generator service
	@echo "$(BLUE)Showing report-generator logs...$(NC)"
	@pnpm logs:report-gen

# Quick development commands
quick-setup: setup ## Quick setup (alias for setup)

quick-dev: ## Quick start development (setup + dev)
	@make setup
	@make dev

quick-test: ## Quick test (type-check + lint + test)
	@make type-check
	@make lint
	@make test

quick-build: ## Quick build (clean + type-check + build)
	@make clean
	@make type-check
	@make build

# Docker commands (when docker-compose.yml exists)
docker-build: ## Build Docker containers
	@if [ -f docker-compose.yml ]; then \
		echo "$(BLUE)Building Docker containers...$(NC)"; \
		docker-compose build; \
	else \
		echo "$(YELLOW)docker-compose.yml not found$(NC)"; \
	fi

docker-up: ## Start Docker containers
	@if [ -f docker-compose.yml ]; then \
		echo "$(BLUE)Starting Docker containers...$(NC)"; \
		docker-compose up -d; \
	else \
		echo "$(YELLOW)docker-compose.yml not found$(NC)"; \
	fi

docker-down: ## Stop Docker containers
	@if [ -f docker-compose.yml ]; then \
		echo "$(BLUE)Stopping Docker containers...$(NC)"; \
		docker-compose down; \
	else \
		echo "$(YELLOW)docker-compose.yml not found$(NC)"; \
	fi

docker-logs: ## Show Docker container logs
	@if [ -f docker-compose.yml ]; then \
		echo "$(BLUE)Showing Docker logs...$(NC)"; \
		docker-compose logs -f; \
	else \
		echo "$(YELLOW)docker-compose.yml not found$(NC)"; \
	fi