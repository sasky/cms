using System.ComponentModel.DataAnnotations;
using System.Text.Json;

namespace cms.Models;

public class ContentItem
{
    [Key]
    public int Id { get; set; }
    
    public JsonDocument Payload { get; set; } = null!;
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
} 