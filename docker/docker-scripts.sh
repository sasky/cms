#!/bin/bash

# CMS Docker Management Script
# This script provides convenient commands for managing the CMS Docker environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# Check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker Desktop."
        exit 1
    fi
}

# Development environment commands
dev_up() {
    print_info "Starting development environment..."
    docker-compose -f docker-compose.dev.yml up --build
}

dev_up_detached() {
    print_info "Starting development environment in background..."
    docker-compose -f docker-compose.dev.yml up --build -d
}

dev_down() {
    print_info "Stopping development environment..."
    docker-compose -f docker-compose.dev.yml down
}

dev_logs() {
    print_info "Showing development logs..."
    docker-compose -f docker-compose.dev.yml logs -f
}

# Production environment commands
prod_up() {
    print_info "Starting production environment..."
    docker-compose up --build -d
}

prod_down() {
    print_info "Stopping production environment..."
    docker-compose down
}

prod_logs() {
    print_info "Showing production logs..."
    docker-compose logs -f
}

# Test commands
test_run() {
    ENV=${1:-dev}
    print_test "Running test suite in $ENV environment..."

    # Create TestResults directory if it doesn't exist
    mkdir -p ../TestResults

    if [ "$ENV" = "dev" ]; then
        docker-compose -f docker-compose.dev.yml --profile test run --rm cms_tests
    else
        docker-compose --profile test run --rm cms_tests
    fi

    print_test "Tests completed. Results saved to ../TestResults/"
}

test_watch() {
    print_test "Starting test watcher in development environment..."

    # Create TestResults directory if it doesn't exist
    mkdir -p ../TestResults

    docker-compose -f docker-compose.dev.yml --profile test up --build cms_tests
}

test_coverage() {
    ENV=${1:-dev}
    print_test "Running tests with coverage analysis..."

    # Create TestResults directory if it doesn't exist
    mkdir -p ../TestResults

    if [ "$ENV" = "dev" ]; then
        docker-compose -f docker-compose.dev.yml --profile test run --rm cms_tests
    else
        docker-compose --profile test run --rm cms_tests
    fi

    print_test "Generating HTML coverage report..."

    # Find the coverage file
    COVERAGE_FILE=$(find ../TestResults -name "coverage.cobertura.xml" | head -1)

    if [ -n "$COVERAGE_FILE" ]; then
        # Generate HTML report using reportgenerator
        docker run --rm -v "$(cd .. && pwd)/TestResults:/TestResults" \
            mcr.microsoft.com/dotnet/sdk:9.0 \
            bash -c "dotnet tool install --global dotnet-reportgenerator-globaltool && \
                     export PATH=\"\$PATH:/root/.dotnet/tools\" && \
                     reportgenerator \
                         -reports:/TestResults/**/coverage.cobertura.xml \
                         -targetdir:/TestResults/CoverageReport \
                         -reporttypes:Html"

        print_test "Coverage report generated at ../TestResults/CoverageReport/index.html"
    else
        print_warning "No coverage file found. Make sure tests ran successfully."
    fi
}

test_unit() {
    ENV=${1:-dev}
    print_test "Running unit tests only..."

    mkdir -p ../TestResults

    if [ "$ENV" = "dev" ]; then
        docker-compose -f docker-compose.dev.yml --profile test run --rm cms_tests \
            dotnet test cms.Tests/cms.Tests.csproj --filter "Category!=Integration" --configuration Debug \
            --logger trx --results-directory /app/TestResults
    else
        docker-compose --profile test run --rm cms_tests \
            dotnet test cms.Tests/cms.Tests.csproj --filter "Category!=Integration" --configuration Release \
            --logger trx --results-directory /app/TestResults
    fi
}

test_integration() {
    ENV=${1:-dev}
    print_test "Running integration tests only..."

    mkdir -p ../TestResults

    if [ "$ENV" = "dev" ]; then
        docker-compose -f docker-compose.dev.yml --profile test run --rm cms_tests \
            dotnet test cms.Tests/cms.Tests.csproj --filter "Category=Integration" --configuration Debug \
            --logger trx --results-directory /app/TestResults
    else
        docker-compose --profile test run --rm cms_tests \
            dotnet test cms.Tests/cms.Tests.csproj --filter "Category=Integration" --configuration Release \
            --logger trx --results-directory /app/TestResults
    fi
}

test_clean() {
    print_test "Cleaning test artifacts..."

    if [ -d "../TestResults" ]; then
        rm -rf ../TestResults/*
        print_test "Test results cleaned"
    fi

    # Clean test containers
    docker-compose -f docker-compose.dev.yml --profile test down
    docker-compose --profile test down

    print_test "Test containers stopped"
}

# Database commands
db_migrate() {
    ENV=${1:-dev}
    if [ "$ENV" = "dev" ]; then
        print_info "Running migrations in development environment..."
        docker exec -it cms_app_dev dotnet ef database update
    else
        print_info "Running migrations in production environment..."
        docker exec -it cms_app dotnet ef database update
    fi
}

db_backup() {
    BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
    print_info "Creating database backup: $BACKUP_FILE"
    docker exec cms_postgres pg_dump -U postgres cms_db >"../$BACKUP_FILE"
    print_info "Backup created successfully: ../$BACKUP_FILE"
}

db_restore() {
    if [ -z "$1" ]; then
        print_error "Please provide backup file path"
        echo "Usage: $0 db-restore <backup_file.sql>"
        exit 1
    fi

    if [ ! -f "$1" ]; then
        print_error "Backup file not found: $1"
        exit 1
    fi

    print_warning "This will overwrite the current database. Are you sure? (y/N)"
    read -r confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        print_info "Restoring database from: $1"
        docker exec -i cms_postgres psql -U postgres cms_db <"$1"
        print_info "Database restored successfully"
    else
        print_info "Restore cancelled"
    fi
}

# Utility commands
clean() {
    print_warning "This will remove all containers, networks, and volumes. Are you sure? (y/N)"
    read -r confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        print_info "Cleaning up Docker resources..."
        docker-compose -f docker-compose.dev.yml down -v
        docker-compose down -v
        docker system prune -f
        print_info "Cleanup complete"
    else
        print_info "Cleanup cancelled"
    fi
}

show_status() {
    print_info "Docker container status:"
    echo ""
    echo "Development containers:"
    docker-compose -f docker-compose.dev.yml ps
    echo ""
    echo "Production containers:"
    docker-compose ps
    echo ""
    echo "Test containers:"
    docker-compose -f docker-compose.dev.yml --profile test ps
    docker-compose --profile test ps
}

# Help function
show_help() {
    echo "CMS Docker Management Script"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Development Commands:"
    echo "  dev-up          Start development environment (interactive)"
    echo "  dev-up-bg       Start development environment (background)"
    echo "  dev-down        Stop development environment"
    echo "  dev-logs        Show development logs"
    echo ""
    echo "Production Commands:"
    echo "  prod-up         Start production environment"
    echo "  prod-down       Stop production environment"
    echo "  prod-logs       Show production logs"
    echo ""
    echo "Test Commands:"
    echo "  test-run [env]        Run all tests (env: dev|prod, default: dev)"
    echo "  test-watch            Run tests in watch mode (development only)"
    echo "  test-coverage [env]   Run tests with coverage analysis"
    echo "  test-unit [env]       Run unit tests only"
    echo "  test-integration [env] Run integration tests only"
    echo "  test-clean            Clean test artifacts and stop test containers"
    echo ""
    echo "Database Commands:"
    echo "  db-migrate [env]    Run database migrations (env: dev|prod, default: dev)"
    echo "  db-backup           Create database backup"
    echo "  db-restore <file>   Restore database from backup file"
    echo ""
    echo "Utility Commands:"
    echo "  status          Show container status"
    echo "  clean           Clean up all Docker resources"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 test-run              # Run tests in development"
    echo "  $0 test-coverage prod    # Run tests with coverage in production"
    echo "  $0 test-watch           # Watch tests in development"
    echo "  $0 test-unit dev        # Run only unit tests in development"
    echo ""
}

# Main command handler
main() {
    check_docker

    case "$1" in
    "dev-up")
        dev_up
        ;;
    "dev-up-bg")
        dev_up_detached
        ;;
    "dev-down")
        dev_down
        ;;
    "dev-logs")
        dev_logs
        ;;
    "prod-up")
        prod_up
        ;;
    "prod-down")
        prod_down
        ;;
    "prod-logs")
        prod_logs
        ;;
    "test-run")
        test_run "$2"
        ;;
    "test-watch")
        test_watch
        ;;
    "test-coverage")
        test_coverage "$2"
        ;;
    "test-unit")
        test_unit "$2"
        ;;
    "test-integration")
        test_integration "$2"
        ;;
    "test-clean")
        test_clean
        ;;
    "db-migrate")
        db_migrate "$2"
        ;;
    "db-backup")
        db_backup
        ;;
    "db-restore")
        db_restore "$2"
        ;;
    "status")
        show_status
        ;;
    "clean")
        clean
        ;;
    "help" | "--help" | "-h" | "")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
    esac
}

# Run main function with all arguments
main "$@"
