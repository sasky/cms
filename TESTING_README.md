# Testing with Docker

This guide explains how to run tests for the CMS project using Docker containers.

## Overview

The Docker test setup provides:
- **Isolated test environment** with PostgreSQL test database
- **Code coverage analysis** with HTML reports  
- **Test watching** for development with hot reload
- **Unit and integration test separation**
- **CI/CD ready** configurations

## Quick Start

### Simple Test Run
```bash
# Run all tests in development environment
./run-tests.sh

# Run tests with coverage analysis
./run-tests.sh --coverage

# Run tests in watch mode (development only)
./run-tests.sh --watch
```

### Advanced Usage
```bash
# Run only unit tests in production environment
./run-tests.sh --unit --prod

# Clean artifacts and run tests with coverage
./run-tests.sh --clean --coverage

# Run only integration tests
./run-tests.sh --integration
```

## Detailed Commands

### Using docker-scripts.sh

The main Docker management script provides these test commands:

#### Run All Tests
```bash
# Development environment (default)
./docker-scripts.sh test-run

# Production environment
./docker-scripts.sh test-run prod
```

#### Test with Coverage
```bash
# Run tests and generate coverage report
./docker-scripts.sh test-coverage

# Production environment
./docker-scripts.sh test-coverage prod
```

#### Watch Mode (Development Only)
```bash
# Automatically re-run tests when code changes
./docker-scripts.sh test-watch
```

#### Unit Tests Only
```bash
# Filter to run only unit tests
./docker-scripts.sh test-unit

# In production environment
./docker-scripts.sh test-unit prod
```

#### Integration Tests Only
```bash
# Filter to run only integration tests
./docker-scripts.sh test-integration

# In production environment
./docker-scripts.sh test-integration prod
```

#### Clean Test Artifacts
```bash
# Remove test results and stop test containers
./docker-scripts.sh test-clean
```

## Test Configuration

### Test Categories

Tests can be categorized using xUnit traits:

```csharp
[Fact]
[Trait("Category", "Unit")]
public void UnitTest_Example()
{
    // Unit test code
}

[Fact]
[Trait("Category", "Integration")]
public void IntegrationTest_Example()
{
    // Integration test code
}
```

### Test Database

- **Development**: Uses `cms_test_db` database
- **Production**: Uses `cms_test_db` database  
- **Connection**: Automatically configured via environment variables

### Test Environment Variables

The test containers use these environment variables:
- `ASPNETCORE_ENVIRONMENT=Testing`
- `ConnectionStrings__DefaultConnection=Host=postgres;Database=cms_test_db;Username=postgres;Password=cms_password_123`

## Access Points

### Development Environment
- **Application HTTP**: http://localhost:5500
- **Application HTTPS**: https://localhost:5501  
- **Swagger UI**: http://localhost:5500/swagger
- **PostgreSQL**: localhost:5432

### Production Environment
- **Application HTTP**: http://localhost:8080
- **PostgreSQL**: localhost:5432

**Note:** Development uses ports 5500/5501 instead of 5000/5001 to avoid conflicts with macOS AirPlay Receiver.

## Test Results and Coverage

### Test Results Location
All test results are saved to the `./TestResults/` directory:
```
TestResults/
├── TestResults_*.trx           # Test result files
├── coverage.cobertura.xml      # Coverage data
└── CoverageReport/             # HTML coverage report
    └── index.html             # Coverage report homepage
```

### Viewing Coverage Reports
After running tests with coverage:
```bash
# Open the coverage report in your browser
open TestResults/CoverageReport/index.html
```

### Coverage Configuration
Coverage settings are configured in `coverlet.runsettings`:
- Excludes test assemblies and generated code
- Includes multiple report formats (Cobertura, OpenCover, LCOV)
- Excludes Views and wwwroot files
- Generates deterministic reports

## Docker Test Architecture

### Test Containers

#### Development Test Container (`cms_tests_dev`)
- Uses `Dockerfile.test` 
- Volume mounts source code for live reload
- Runs with `--watch` flag for automatic re-runs
- Debug configuration

#### Production Test Container (`cms_tests`)
- Uses `Dockerfile.test`
- No volume mounting
- Release configuration
- Optimized for CI/CD

### Test-Specific Dockerfile

The `Dockerfile.test` includes:
- .NET 9.0 SDK with test tools
- Entity Framework tools for migrations
- ReportGenerator for coverage reports
- Test result directories
- Coverlet for code coverage

## Integration with CI/CD

### GitHub Actions Example
```yaml
- name: Run Tests with Coverage
  run: |
    docker-compose --profile test run --rm cms_tests
    
- name: Upload Coverage Reports
  uses: codecov/codecov-action@v3
  with:
    file: ./TestResults/coverage.cobertura.xml
```

### Test Profiles

Both docker-compose files use profiles to separate test services:
```bash
# Include test services
docker-compose --profile test up

# Exclude test services (default)
docker-compose up
```

## Troubleshooting

### Common Issues

#### Port Conflicts
If you see port conflicts, ensure the main application isn't running:
```bash
./docker-scripts.sh dev-down
./docker-scripts.sh prod-down
```

**macOS AirPlay Receiver**: Development uses ports 5500/5501 instead of 5000/5001 to avoid conflicts with AirPlay Receiver which uses port 5000 by default.

#### Database Connection Issues
Tests use a separate test database (`cms_test_db`). If you see connection issues:
```bash
# Check PostgreSQL container status
docker-compose ps postgres

# View PostgreSQL logs
docker-compose logs postgres
```

#### Test Container Build Issues
If the test container fails to build:
```bash
# Rebuild test container
docker-compose --profile test build cms_tests

# View build logs
docker-compose --profile test build --no-cache cms_tests
```

#### Coverage Report Not Generated
Ensure tests run successfully first:
```bash
# Clean and retry
./docker-scripts.sh test-clean
./docker-scripts.sh test-coverage
```

### Debugging Tests

#### Access Test Container
```bash
# Connect to running test container (development)
docker exec -it cms_tests_dev bash

# Run specific test commands
dotnet test --filter "MethodName=SpecificTest"
```

#### View Test Logs
```bash
# View test container logs
docker-compose --profile test logs cms_tests

# Follow logs in real-time
docker-compose --profile test logs -f cms_tests
```

## Performance Considerations

### Development vs Production

**Development Environment:**
- Volume mounting for live reload
- Debug configuration
- Watch mode available
- Slower but more convenient

**Production Environment:**
- No volume mounting
- Release configuration optimized
- Faster execution
- CI/CD ready

### Test Execution Speed
- Unit tests run faster (no database)
- Integration tests require database setup
- Use test categories to run subsets
- Parallel test execution enabled by default

## Best Practices

### Writing Testable Code
1. Use dependency injection
2. Separate unit tests from integration tests
3. Use traits/categories for test organization
4. Mock external dependencies

### Test Organization
```
cms.Tests/
├── Controllers/           # Controller tests
├── Services/             # Service layer tests  
├── Integration/          # Integration tests
├── Unit/                 # Unit tests
└── Helpers/              # Test utilities
```

### Test Data Management
- Use Entity Framework InMemory for unit tests
- Use test database for integration tests
- Clean up test data between tests
- Use factories for test data generation

## Advanced Configuration

### Custom Test Settings
Create `appsettings.Testing.json` for test-specific configuration:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=postgres;Database=cms_test_db;Username=postgres;Password=cms_password_123"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Warning"
    }
  }
}
```

### Custom Coverage Rules
Modify `coverlet.runsettings` to customize coverage:
```xml
<Exclude>[*]*.Program,[*]*.Startup</Exclude>
<Threshold>80</Threshold>
```

### Test Parallelization
Configure parallel test execution in test projects:
```xml
<PropertyGroup>
  <ParallelizeTestCollections>true</ParallelizeTestCollections>
  <MaxParallelThreads>4</MaxParallelThreads>
</PropertyGroup>
``` 