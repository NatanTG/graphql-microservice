#!/bin/bash

# Update Script for GraphQL Microservice
# Atualiza dependências e repositórios

set -e

echo "🔄 Updating GraphQL Microservice Workspace..."
echo "============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[UPDATE]${NC} $1"
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
DEPENDENCIES=false
FORCE=false
PROJECT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --deps|-d)
            DEPENDENCIES=true
            shift
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --project|-p)
            PROJECT="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -d, --deps        Update dependencies to latest versions"
            echo "  -f, --force       Force reinstall all dependencies"
            echo "  -p, --project     Update specific project (core|report-generator)"
            echo "  -h, --help        Show this help"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Function to update git repository
update_git() {
    local project_name=$1
    local project_path=$2
    
    if [ ! -d "$project_path" ]; then
        print_error "$project_name project not found at $project_path"
        return 1
    fi
    
    print_status "Updating $project_name repository..."
    
    cd "$project_path"
    
    # Check if it's a git repository
    if [ ! -d ".git" ]; then
        print_warning "$project_name is not a git repository"
        cd ..
        return 0
    fi
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        print_warning "$project_name has uncommitted changes"
        if [ "$FORCE" = false ]; then
            print_error "Use --force to proceed with uncommitted changes"
            cd ..
            return 1
        fi
    fi
    
    # Pull latest changes
    if git pull origin main 2>/dev/null; then
        print_success "$project_name repository updated"
    else
        print_warning "$project_name repository update failed or no remote configured"
    fi
    
    cd ..
    return 0
}

# Function to update project dependencies
update_dependencies() {
    local project_name=$1
    local project_path=$2
    
    if [ ! -d "$project_path" ]; then
        print_error "$project_name project not found at $project_path"
        return 1
    fi
    
    print_status "Updating $project_name dependencies..."
    
    cd "$project_path"
    
    if [ "$FORCE" = true ]; then
        print_status "Force reinstalling dependencies for $project_name..."
        rm -rf node_modules pnpm-lock.yaml
        pnpm install
    elif [ "$DEPENDENCIES" = true ]; then
        print_status "Updating dependencies to latest versions for $project_name..."
        pnpm update
    else
        print_status "Installing dependencies for $project_name..."
        pnpm install
    fi
    
    # Audit for vulnerabilities
    print_status "Checking for security vulnerabilities in $project_name..."
    if pnpm audit --audit-level high; then
        print_success "$project_name dependencies are secure"
    else
        print_warning "$project_name has dependency vulnerabilities"
        print_status "Run 'pnpm audit --fix' in $project_path to fix automatically"
    fi
    
    # Check for outdated packages
    if [ "$DEPENDENCIES" = false ]; then
        print_status "Checking for outdated packages in $project_name..."
        pnpm outdated || print_warning "$project_name has outdated packages. Use --deps to update."
    fi
    
    cd ..
    print_success "$project_name dependencies updated"
    return 0
}

# Function to verify project health
verify_project() {
    local project_name=$1
    local project_path=$2
    
    print_status "Verifying $project_name..."
    
    cd "$project_path"
    
    # Type check
    if pnpm type-check; then
        print_success "$project_name types are valid"
    else
        print_error "$project_name has type errors"
        cd ..
        return 1
    fi
    
    # Quick test
    if pnpm test > /dev/null 2>&1; then
        print_success "$project_name tests pass"
    else
        print_warning "$project_name tests are failing"
    fi
    
    cd ..
    return 0
}

# Track update results
CORE_RESULT=0
REPORT_GEN_RESULT=0

# Update based on project filter
if [ -z "$PROJECT" ] || [ "$PROJECT" = "core" ]; then
    print_status "=== Updating Core ==="
    update_git "Core" "core"
    update_dependencies "Core" "core"
    verify_project "Core" "core"
    CORE_RESULT=$?
fi

if [ -z "$PROJECT" ] || [ "$PROJECT" = "report-generator" ]; then
    print_status "=== Updating Report Generator ==="
    update_git "Report Generator" "report-generator"
    update_dependencies "Report Generator" "report-generator"
    verify_project "Report Generator" "report-generator"
    REPORT_GEN_RESULT=$?
fi

# Update workspace itself
print_status "=== Updating Workspace ==="
if [ ! -z "$(git status --porcelain)" ]; then
    print_warning "Workspace has uncommitted changes"
fi

# Generate update summary
echo ""
echo "📊 Update Summary"
echo "================="

if [ -z "$PROJECT" ] || [ "$PROJECT" = "core" ]; then
    if [ $CORE_RESULT -eq 0 ]; then
        print_success "Core: Updated successfully"
    else
        print_error "Core: Update issues detected"
    fi
fi

if [ -z "$PROJECT" ] || [ "$PROJECT" = "report-generator" ]; then
    if [ $REPORT_GEN_RESULT -eq 0 ]; then
        print_success "Report Generator: Updated successfully"
    else
        print_error "Report Generator: Update issues detected"
    fi
fi

# Overall result
OVERALL_RESULT=$((CORE_RESULT + REPORT_GEN_RESULT))

echo ""
if [ $OVERALL_RESULT -eq 0 ]; then
    print_success "🎉 Workspace updated successfully!"
    
    echo ""
    print_status "Next steps:"
    echo "  🔧 Test: ./scripts/test.sh"
    echo "  🔨 Build: ./scripts/build.sh"
    echo "  🚀 Develop: ./scripts/dev.sh"
    
    exit 0
else
    print_error "❌ Some updates had issues. Check the output above for details."
    exit 1
fi