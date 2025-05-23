#!/bin/bash

# Quick Test Runner for CMS Project
# This is a simplified wrapper around the main docker-scripts.sh for common test scenarios

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# Default to development environment
ENV="dev"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --prod | --production)
        ENV="prod"
        shift
        ;;
    --dev | --development)
        ENV="dev"
        shift
        ;;
    --coverage | -c)
        COVERAGE=true
        shift
        ;;
    --watch | -w)
        WATCH=true
        shift
        ;;
    --unit | -u)
        UNIT_ONLY=true
        shift
        ;;
    --integration | -i)
        INTEGRATION_ONLY=true
        shift
        ;;
    --clean)
        CLEAN=true
        shift
        ;;
    --help | -h)
        echo "Quick Test Runner for CMS Project"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --dev, --development    Run tests in development environment (default)"
        echo "  --prod, --production    Run tests in production environment"
        echo "  --coverage, -c          Include code coverage analysis"
        echo "  --watch, -w             Run tests in watch mode (development only)"
        echo "  --unit, -u              Run unit tests only"
        echo "  --integration, -i       Run integration tests only"
        echo "  --clean                 Clean test artifacts before running"
        echo "  --help, -h              Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                      # Run all tests in development"
        echo "  $0 --coverage           # Run tests with coverage"
        echo "  $0 --watch              # Watch tests in development"
        echo "  $0 --unit --prod        # Run unit tests in production"
        echo "  $0 --clean --coverage   # Clean and run with coverage"
        echo ""
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
    esac
done

# Main execution logic
main() {
    print_info "CMS Test Runner"

    # Clean if requested
    if [ "$CLEAN" = true ]; then
        print_test "Cleaning test artifacts..."
        ./docker-scripts.sh test-clean
    fi

    # Determine which test command to run
    if [ "$WATCH" = true ]; then
        if [ "$ENV" = "prod" ]; then
            print_info "Watch mode is only available in development environment"
            ENV="dev"
        fi
        print_test "Starting test watcher in development environment..."
        ./docker-scripts.sh test-watch
    elif [ "$COVERAGE" = true ]; then
        print_test "Running tests with coverage analysis in $ENV environment..."
        ./docker-scripts.sh test-coverage "$ENV"
    elif [ "$UNIT_ONLY" = true ]; then
        print_test "Running unit tests only in $ENV environment..."
        ./docker-scripts.sh test-unit "$ENV"
    elif [ "$INTEGRATION_ONLY" = true ]; then
        print_test "Running integration tests only in $ENV environment..."
        ./docker-scripts.sh test-integration "$ENV"
    else
        print_test "Running all tests in $ENV environment..."
        ./docker-scripts.sh test-run "$ENV"
    fi
}

# Check if docker-scripts.sh exists
if [ ! -f "./docker-scripts.sh" ]; then
    echo "Error: docker-scripts.sh not found in current directory"
    exit 1
fi

# Make sure docker-scripts.sh is executable
chmod +x ./docker-scripts.sh

# Run main function
main
