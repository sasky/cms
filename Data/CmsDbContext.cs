using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using cms.Models;
using System.Text.Json;

namespace cms.Data;

public class CmsDbContext : DbContext
{
    public CmsDbContext(DbContextOptions<CmsDbContext> options) : base(options)
    {
    }

    public DbSet<ContentItem> ContentItems { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Create a value converter for JsonDocument
        var jsonDocumentConverter = new ValueConverter<JsonDocument, string>(
            v => v.RootElement.GetRawText(),
            v => JsonDocument.Parse(v, new JsonDocumentOptions()));

        modelBuilder.Entity<ContentItem>(entity =>
        {
            entity.HasKey(e => e.Id);

            // Configure the Payload property
            var payloadProperty = entity.Property(e => e.Payload)
                  .IsRequired();

            // Use different configurations based on the database provider
            if (Database.IsNpgsql())
            {
                // For PostgreSQL, use jsonb column type
                payloadProperty.HasColumnType("jsonb");
            }
            else
            {
                // For other providers (like InMemory), use the value converter
                payloadProperty.HasConversion(jsonDocumentConverter);
            }

            entity.Property(e => e.CreatedAt)
                  .HasDefaultValueSql("CURRENT_TIMESTAMP");
            entity.Property(e => e.UpdatedAt)
                  .HasDefaultValueSql("CURRENT_TIMESTAMP");
        });
    }
}