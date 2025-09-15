#!/bin/bash

# Setup Script for GraphQL Microservice Workspace
# Configura ambiente completo para desenvolvimento

set -e  # Exit on any error

echo "🚀 Setting up GraphQL Microservice Workspace..."
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    print_error "Node.js version must be 18 or higher. Current: $(node --version)"
    exit 1
fi

# Check if pnpm is installed
if ! command -v pnpm &> /dev/null; then
    print_warning "pnpm not found. Installing pnpm..."
    npm install -g pnpm
fi

print_success "Node.js $(node --version) and pnpm $(pnpm --version) are ready"

# Function to setup project dependencies
setup_project() {
    local project_name=$1
    local project_path=$2
    
    print_status "Setting up $project_name..."
    
    if [ -d "$project_path" ]; then
        cd "$project_path"
        
        # Install dependencies
        print_status "Installing dependencies for $project_name..."
        pnpm install
        
        # Create .env from example if it doesn't exist
        if [ -f ".env.example" ] && [ ! -f ".env" ]; then
            print_status "Creating .env file for $project_name..."
            cp .env.example .env
            print_warning "Please configure .env file for $project_name"
        fi
        
        # Run type check
        if pnpm run type-check &> /dev/null; then
            print_success "TypeScript types are valid for $project_name"
        else
            print_warning "TypeScript type check failed for $project_name"
        fi
        
        cd ..
        print_success "$project_name setup completed"
    else
        print_error "Directory $project_path not found"
        return 1
    fi
}

# Setup Core project
setup_project "Core" "core"

# Setup Report Generator project  
setup_project "Report Generator" "report-generator"

# Check if MongoDB is running (optional)
print_status "Checking MongoDB connection..."
if command -v mongosh &> /dev/null; then
    if mongosh --eval "db.adminCommand('ping')" --quiet &> /dev/null; then
        print_success "MongoDB is running and accessible"
    else
        print_warning "MongoDB is not running. Please start MongoDB before running the applications."
        print_status "To start MongoDB with Docker: docker run -d -p 27017:27017 --name mongodb mongo:6"
    fi
else
    print_warning "MongoDB CLI (mongosh) not found. Install MongoDB to test connectivity."
fi

# Check if Google Cloud CLI is available (optional)
if command -v gcloud &> /dev/null; then
    print_success "Google Cloud CLI is available"
    print_status "To setup Pub/Sub emulator: gcloud components install pubsub-emulator"
else
    print_warning "Google Cloud CLI not found. Install it for Pub/Sub integration."
    print_status "Install: curl https://sdk.cloud.google.com | bash"
fi

# Create necessary directories
mkdir -p logs
mkdir -p temp
mkdir -p reports

print_success "Workspace setup completed! 🎉"
echo ""
echo "Next steps:"
echo "1. Configure .env files in core/ and report-generator/"
echo "2. Start MongoDB: docker run -d -p 27017:27017 --name mongodb mongo:6"
echo "3. Start development: ./scripts/dev.sh"
echo "4. Run tests: ./scripts/test.sh"
echo ""
echo "For more information, see: ./setup.md"