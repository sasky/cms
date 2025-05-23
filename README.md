# Headless CMS

A modern headless REST-based CMS built with .NET 9, Entity Framework Core, and PostgreSQL.

## Features

- RESTful API for content management
- PostgreSQL database with JSON support
- Comprehensive unit testing
- Swagger/OpenAPI documentation
- Modern C# with nullable reference types enabled

## Project Structure

```
cms/
├── Controllers/
│   └── ContentController.cs    # REST API controller
├── Data/
│   └── CmsDbContext.cs        # Entity Framework context
├── Models/
│   └── ContentItem.cs         # Data model
├── cms.Tests/
│   └── Controllers/
│       └── ContentControllerTests.cs  # Unit tests
├── Program.cs                 # Application entry point
├── cms.csproj                 # Project file
└── appsettings.json          # Configuration
```

## Prerequisites

- .NET 9 SDK
- PostgreSQL database
- (Optional) Docker for database setup

## Setup

### 1. Clone and Restore Packages

```bash
cd cms
dotnet restore
```

### 2. Database Setup

#### Option A: Local PostgreSQL
1. Install PostgreSQL on your machine
2. Create a database named `cms_dev_db`
3. Update the connection string in `appsettings.Development.json`

#### Option B: Docker PostgreSQL
```bash
docker run --name postgres-cms \
  -e POSTGRES_DB=cms_dev_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=your_password_here \
  -p 5432:5432 \
  -d postgres:15
```

### 3. Update Configuration

Edit `appsettings.Development.json` and update the connection string:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=cms_dev_db;Username=postgres;Password=your_actual_password"
  }
}
```

### 4. Create and Run Migrations

```bash
# Install EF Core tools (if not already installed)
dotnet tool install --global dotnet-ef

# Create initial migration
dotnet ef migrations add InitialCreate

# Update database
dotnet ef database update
```

### 5. Run the Application

```bash
dotnet run
```

The API will be available at:
- HTTP: `http://localhost:5000`
- HTTPS: `https://localhost:5001`
- Swagger UI: `https://localhost:5001/swagger`

## API Endpoints

### Content Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/content` | Get all content items |
| GET | `/api/content/{id}` | Get specific content item |
| POST | `/api/content` | Create new content item |
| PUT | `/api/content/{id}` | Update existing content item |
| DELETE | `/api/content/{id}` | Delete content item |

### Request/Response Examples

#### Create Content Item
```bash
POST /api/content
Content-Type: application/json

{
  "payload": "{\"title\":\"My Article\",\"content\":\"Article content here\",\"tags\":[\"tech\",\"dotnet\"]}"
}
```

#### Response
```json
{
  "id": 1,
  "payload": {
    "title": "My Article",
    "content": "Article content here",
    "tags": ["tech", "dotnet"]
  },
  "createdAt": "2024-01-01T12:00:00Z",
  "updatedAt": "2024-01-01T12:00:00Z"
}
```

## Data Model

The core data model follows the specification:

```csharp
public class ContentItem
{
    public int Id { get; set; }           // Primary key
    public JsonDocument Payload { get; set; }  // JSON content
    public DateTime CreatedAt { get; set; }    // Creation timestamp
    public DateTime UpdatedAt { get; set; }    // Last update timestamp
}
```

## Testing

Run the comprehensive unit test suite:

```bash
# Run all tests
dotnet test

# Run tests with coverage
dotnet test --collect:"XPlat Code Coverage"

# Run specific test class
dotnet test --filter "ContentControllerTests"
```

The test suite covers:
- CRUD operations
- Error handling
- Input validation
- Database integration

## Development

### Adding New Features

1. Create new controllers in `Controllers/`
2. Add corresponding models in `Models/`
3. Update `CmsDbContext` if new entities are needed
4. Write comprehensive unit tests
5. Update API documentation

### Database Migrations

When modifying models:

```bash
# Create new migration
dotnet ef migrations add YourMigrationName

# Update database
dotnet ef database update
```

## Technology Stack

- **.NET 9**: Modern C# runtime
- **ASP.NET Core Web API**: REST API framework
- **Entity Framework Core**: ORM with PostgreSQL provider
- **PostgreSQL**: Database with JSON support
- **xUnit**: Unit testing framework
- **Moq**: Mocking framework for tests
- **Swagger/OpenAPI**: API documentation

## Contributing

1. Follow C# coding conventions
2. Write unit tests for all new features
3. Update documentation for API changes
4. Use meaningful commit messages

## License

This project is for learning purposes. 