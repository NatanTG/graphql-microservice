#!/bin/bash

# Build Script for GraphQL Microservice
# Compila ambos os projetos e verifica tipos

set -e

echo "🔨 Building GraphQL Microservice Projects..."
echo "============================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[BUILD]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Parse command line arguments
CLEAN=false
PRODUCTION=false
PROJECT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN=true
            shift
            ;;
        --production)
            PRODUCTION=true
            shift
            ;;
        --project|-p)
            PROJECT="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --clean           Clean build directories before building"
            echo "  --production      Build for production environment"
            echo "  -p, --project     Build specific project (core|report-generator)"
            echo "  -h, --help        Show this help"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Function to build a project
build_project() {
    local project_name=$1
    local project_path=$2
    
    if [ ! -d "$project_path" ]; then
        print_error "$project_name project not found at $project_path"
        return 1
    fi
    
    if [ ! -d "$project_path/node_modules" ]; then
        print_error "$project_name dependencies not installed. Run ./scripts/setup.sh first."
        return 1
    fi
    
    print_status "Building $project_name..."
    
    cd "$project_path"
    
    # Clean if requested
    if [ "$CLEAN" = true ]; then
        print_status "Cleaning $project_name build directory..."
        pnpm clean 2>/dev/null || rm -rf dist/ || true
    fi
    
    # Type check first
    print_status "Type checking $project_name..."
    if pnpm type-check; then
        print_success "$project_name types are valid"
    else
        print_error "$project_name type check failed"
        cd ..
        return 1
    fi
    
    # Lint check
    print_status "Linting $project_name..."
    if pnpm lint; then
        print_success "$project_name linting passed"
    else
        print_warning "$project_name has linting issues"
    fi
    
    # Build the project
    print_status "Compiling $project_name..."
    if pnpm build; then
        print_success "$project_name built successfully"
        
        # Show build info
        if [ -d "dist" ]; then
            BUILD_SIZE=$(du -sh dist/ | cut -f1)
            print_status "$project_name build size: $BUILD_SIZE"
        fi
    else
        print_error "$project_name build failed"
        cd ..
        return 1
    fi
    
    cd ..
    return 0
}

# Track build results
CORE_RESULT=0
REPORT_GEN_RESULT=0

# Build based on project filter
if [ -z "$PROJECT" ] || [ "$PROJECT" = "core" ]; then
    build_project "Core" "core"
    CORE_RESULT=$?
fi

if [ -z "$PROJECT" ] || [ "$PROJECT" = "report-generator" ]; then
    build_project "Report Generator" "report-generator"
    REPORT_GEN_RESULT=$?
fi

# Generate build summary
echo ""
echo "📦 Build Summary"
echo "================"

if [ -z "$PROJECT" ] || [ "$PROJECT" = "core" ]; then
    if [ $CORE_RESULT -eq 0 ]; then
        print_success "Core: Build successful"
        [ -d "core/dist" ] && echo "  📁 Output: core/dist/"
    else
        print_error "Core: Build failed"
    fi
fi

if [ -z "$PROJECT" ] || [ "$PROJECT" = "report-generator" ]; then
    if [ $REPORT_GEN_RESULT -eq 0 ]; then
        print_success "Report Generator: Build successful"
        [ -d "report-generator/dist" ] && echo "  📁 Output: report-generator/dist/"
    else
        print_error "Report Generator: Build failed"
    fi
fi

# Overall result
OVERALL_RESULT=$((CORE_RESULT + REPORT_GEN_RESULT))

echo ""
if [ $OVERALL_RESULT -eq 0 ]; then
    print_success "🎉 All projects built successfully!"
    
    echo ""
    print_status "Next steps:"
    if [ "$PRODUCTION" = true ]; then
        echo "  🚀 Deploy: Use built files in dist/ directories"
        echo "  🐳 Docker: Build container images"
    else
        echo "  🔧 Test: ./scripts/test.sh"
        echo "  🚀 Start: cd core && pnpm start"
        echo "  🚀 Start: cd report-generator && pnpm start"
    fi
    
    exit 0
else
    print_error "❌ Some builds failed. Check the output above for details."
    exit 1
fi