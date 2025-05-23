using Microsoft.EntityFrameworkCore;
using cms.Models;

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

        modelBuilder.Entity<ContentItem>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Payload)
                  .HasColumnType("jsonb")
                  .IsRequired();
            entity.Property(e => e.CreatedAt)
                  .HasDefaultValueSql("CURRENT_TIMESTAMP");
            entity.Property(e => e.UpdatedAt)
                  .HasDefaultValueSql("CURRENT_TIMESTAMP");
        });
    }
} 