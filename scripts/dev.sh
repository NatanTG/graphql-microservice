#!/bin/bash

# Development Script for GraphQL Microservice
# Executa ambos os projetos em modo de desenvolvimento

set -e

echo "🔥 Starting GraphQL Microservice Development Environment..."
echo "========================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[DEV]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if projects exist
if [ ! -d "core" ]; then
    print_error "Core project not found. Run ./scripts/setup.sh first."
    exit 1
fi

if [ ! -d "report-generator" ]; then
    print_error "Report Generator project not found. Run ./scripts/setup.sh first."
    exit 1
fi

# Check if dependencies are installed
if [ ! -d "core/node_modules" ]; then
    print_error "Core dependencies not installed. Run ./scripts/setup.sh first."
    exit 1
fi

if [ ! -d "report-generator/node_modules" ]; then
    print_error "Report Generator dependencies not installed. Run ./scripts/setup.sh first."
    exit 1
fi

# Function to kill background processes on exit
cleanup() {
    print_status "Shutting down development environment..."
    if [ ! -z "$CORE_PID" ]; then
        kill $CORE_PID 2>/dev/null || true
    fi
    if [ ! -z "$REPORT_GEN_PID" ]; then
        kill $REPORT_GEN_PID 2>/dev/null || true
    fi
    print_success "Development environment stopped"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Check environment files
check_env() {
    local project_name=$1
    local project_path=$2
    
    if [ ! -f "$project_path/.env" ]; then
        print_error ".env file not found in $project_name. Copy from .env.example and configure."
        return 1
    fi
}

print_status "Checking environment configuration..."
check_env "Core" "core"
check_env "Report Generator" "report-generator"

# Create log directory
mkdir -p logs

print_status "Starting Core (GraphQL API) on port 4000..."
cd core
pnpm dev > ../logs/core.log 2>&1 &
CORE_PID=$!
cd ..

print_status "Starting Report Generator on background..."
cd report-generator  
pnpm dev > ../logs/report-generator.log 2>&1 &
REPORT_GEN_PID=$!
cd ..

# Wait a moment for services to start
sleep 3

# Check if services are running
if kill -0 $CORE_PID 2>/dev/null; then
    print_success "Core is running (PID: $CORE_PID)"
    print_status "GraphQL API: http://localhost:4000/graphql"
else
    print_error "Failed to start Core. Check logs/core.log"
    exit 1
fi

if kill -0 $REPORT_GEN_PID 2>/dev/null; then
    print_success "Report Generator is running (PID: $REPORT_GEN_PID)"
else
    print_error "Failed to start Report Generator. Check logs/report-generator.log"
    exit 1
fi

echo ""
print_success "Development environment is ready! 🚀"
echo ""
echo "Services:"
echo "  📊 GraphQL API: http://localhost:4000/graphql"
echo "  📁 Report Generator: Running in background"
echo ""
echo "Logs:"
echo "  📄 Core: tail -f logs/core.log"
echo "  📄 Report Generator: tail -f logs/report-generator.log"
echo ""
echo "Commands:"
echo "  🧪 Run tests: ./scripts/test.sh"
echo "  🔧 Build projects: ./scripts/build.sh"
echo "  🔄 Update dependencies: ./scripts/update.sh"
echo ""
echo "Press Ctrl+C to stop all services"

# Keep script running and show live logs
tail -f logs/core.log logs/report-generator.log