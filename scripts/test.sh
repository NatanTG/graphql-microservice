#!/bin/bash

# Test Script for GraphQL Microservice
# Executa testes em ambos os projetos com relatórios

set -e

echo "🧪 Running GraphQL Microservice Tests..."
echo "======================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[TEST]${NC} $1"
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
COVERAGE=false
WATCH=false
VERBOSE=false
PROJECT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --coverage|-c)
            COVERAGE=true
            shift
            ;;
        --watch|-w)
            WATCH=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --project|-p)
            PROJECT="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -c, --coverage    Run tests with coverage"
            echo "  -w, --watch       Run tests in watch mode"
            echo "  -v, --verbose     Run tests in verbose mode"
            echo "  -p, --project     Run tests for specific project (core|report-generator)"
            echo "  -h, --help        Show this help"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Function to run tests for a project
run_tests() {
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
    
    print_status "Running tests for $project_name..."
    
    cd "$project_path"
    
    local test_cmd="pnpm test"
    
    # Add flags based on options
    if [ "$COVERAGE" = true ]; then
        test_cmd="pnpm test:coverage"
    elif [ "$WATCH" = true ]; then
        test_cmd="pnpm test:watch"
    elif [ "$VERBOSE" = true ]; then
        test_cmd="pnpm test:verbose"
    fi
    
    # Run tests
    if $test_cmd; then
        print_success "$project_name tests passed ✅"
        cd ..
        return 0
    else
        print_error "$project_name tests failed ❌"
        cd ..
        return 1
    fi
}

# Create reports directory
mkdir -p reports

# Track test results
CORE_RESULT=0
REPORT_GEN_RESULT=0

# Run tests based on project filter
if [ -z "$PROJECT" ] || [ "$PROJECT" = "core" ]; then
    run_tests "Core" "core"
    CORE_RESULT=$?
fi

if [ -z "$PROJECT" ] || [ "$PROJECT" = "report-generator" ]; then
    run_tests "Report Generator" "report-generator"
    REPORT_GEN_RESULT=$?
fi

# Generate test summary
echo ""
echo "📊 Test Summary"
echo "==============="

if [ -z "$PROJECT" ] || [ "$PROJECT" = "core" ]; then
    if [ $CORE_RESULT -eq 0 ]; then
        print_success "Core: All tests passed"
    else
        print_error "Core: Tests failed"
    fi
fi

if [ -z "$PROJECT" ] || [ "$PROJECT" = "report-generator" ]; then
    if [ $REPORT_GEN_RESULT -eq 0 ]; then
        print_success "Report Generator: All tests passed"
    else
        print_error "Report Generator: Tests failed"
    fi
fi

# Overall result
OVERALL_RESULT=$((CORE_RESULT + REPORT_GEN_RESULT))

echo ""
if [ $OVERALL_RESULT -eq 0 ]; then
    print_success "🎉 All tests passed successfully!"
    
    if [ "$COVERAGE" = true ]; then
        echo ""
        print_status "Coverage reports generated:"
        [ -d "core/coverage" ] && echo "  📄 Core: core/coverage/index.html"
        [ -d "report-generator/coverage" ] && echo "  📄 Report Generator: report-generator/coverage/index.html"
    fi
    
    exit 0
else
    print_error "❌ Some tests failed. Check the output above for details."
    exit 1
fi