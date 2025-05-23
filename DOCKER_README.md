# Docker Setup for CMS Project

This document provides instructions for running the CMS project using Docker containers.

## Prerequisites

- Docker Desktop installed and running
- Docker Compose V2 (included with Docker Desktop)

## Project Structure

```
├── Dockerfile                 # Production build
├── Dockerfile.dev            # Development build with hot reload
├── docker-compose.yml        # Production setup
├── docker-compose.dev.yml    # Development setup
├── .dockerignore            # Files to exclude from Docker context
├── appsettings.Docker.json  # Docker-specific configuration
└── init-scripts/
    └── init.sql             # PostgreSQL initialization script
```

## Quick Start

### Development Environment

1. **Start the development environment:**
   ```bash
   docker-compose -f docker-compose.dev.yml up --build
   ```

2. **Access the application:**
   - HTTP: http://localhost:5500
   - HTTPS: https://localhost:5501
   - Swagger UI: http://localhost:5500/swagger

3. **Access PostgreSQL:**
   - Host: localhost
   - Port: 5432
   - Database: cms_db
   - Username: postgres
   - Password: cms_password_123

**Note:** Development uses ports 5500/5501 to avoid conflicts with macOS AirPlay Receiver which uses port 5000.

### Production Environment

1. **Start the production environment:**
   ```bash
   docker-compose up --build -d
   ```

2. **Access the application:**
   - HTTP: http://localhost:8080

## Database Management

### Running Migrations

For development environment:
```bash
# Connect to the running development container
docker exec -it cms_app_dev bash

# Run migrations
dotnet ef database update
```

For production environment:
```bash
# Connect to the running production container
docker exec -it cms_app bash

# Run migrations
dotnet ef database update
```

### Creating New Migrations

In development:
```bash
# Connect to the development container
docker exec -it cms_app_dev bash

# Create a new migration
dotnet ef migrations add MigrationName
```

## Useful Commands

### Viewing Logs
```bash
# View all service logs
docker-compose logs

# View specific service logs
docker-compose logs cms_app
docker-compose logs postgres

# Follow logs in real-time
docker-compose logs -f cms_app
```

### Stopping Services
```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: This will delete database data)
docker-compose down -v
```

### Rebuilding Services
```bash
# Rebuild and restart a specific service
docker-compose up --build cms_app

# Rebuild all services
docker-compose up --build
```

### Database Backup and Restore

#### Backup
```bash
docker exec cms_postgres pg_dump -U postgres cms_db > backup.sql
```

#### Restore
```bash
docker exec -i cms_postgres psql -U postgres cms_db < backup.sql
```

## Environment Variables

The following environment variables are configured in docker-compose files:

### Application
- `ASPNETCORE_ENVIRONMENT`: Set to Development or Production
- `ConnectionStrings__DefaultConnection`: PostgreSQL connection string
- `ASPNETCORE_URLS`: URLs the application listens on

### PostgreSQL
- `POSTGRES_DB`: Database name (cms_db)
- `POSTGRES_USER`: Database user (postgres)
- `POSTGRES_PASSWORD`: Database password (cms_password_123)

## Port Configuration

### Development Environment
- **Application HTTP**: 5500 (mapped from container's 5000)
- **Application HTTPS**: 5501 (mapped from container's 5001)
- **PostgreSQL**: 5432

### Production Environment
- **Application HTTP**: 8080
- **PostgreSQL**: 5432

**Why different development ports?** macOS AirPlay Receiver uses port 5000 by default, so we use 5500/5501 to avoid conflicts.

## Troubleshooting

### Common Issues

1. **Port conflicts**: 
   - **macOS AirPlay Receiver conflict**: We use ports 5500/5501 in development to avoid the common port 5000 conflict
   - **Other conflicts**: If you see port conflicts, modify the port mappings in docker-compose files

2. **Database connection issues**: Ensure PostgreSQL container is healthy before the application starts. The health check should handle this automatically.

3. **Permission issues**: On Linux/macOS, you might need to run Docker commands with `sudo`.

### Disabling macOS AirPlay Receiver (Alternative Solution)

If you prefer to use the standard ports 5000/5001, you can disable AirPlay Receiver:

1. Open **System Preferences** → **Sharing**
2. Uncheck **AirPlay Receiver**

Or via command line:
```bash
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.AirPlayXPCHelper.plist
```

### Health Checks

PostgreSQL includes a health check that verifies the database is ready to accept connections. The application container waits for PostgreSQL to be healthy before starting.

### Viewing Container Status
```bash
# Check if containers are running
docker-compose ps

# Check container health
docker-compose ps
```

## Security Notes

- **Change default passwords** before deploying to production
- **Use environment variables** or Docker secrets for sensitive data
- **Configure firewalls** appropriately for production deployments
- **Use HTTPS** in production (configure certificates)

## Performance Considerations

- **Volume mounting**: Development setup uses volume mounting for hot reload, which may impact performance on Windows/macOS
- **Multi-stage builds**: Production Dockerfile uses multi-stage builds to minimize image size
- **Resource limits**: Consider adding resource limits in production docker-compose files

## Next Steps

1. Configure Entity Framework migrations
2. Set up proper logging and monitoring
3. Configure HTTPS certificates for production
4. Implement proper secrets management
5. Set up CI/CD pipeline for automated deployments
