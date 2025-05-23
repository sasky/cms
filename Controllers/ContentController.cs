using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using cms.Data;
using cms.Models;
using System.Text.Json;

namespace cms.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ContentController : ControllerBase
{
    private readonly CmsDbContext _context;
    private readonly ILogger<ContentController> _logger;

    public ContentController(CmsDbContext context, ILogger<ContentController> logger)
    {
        _context = context;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ContentItem>>> GetContentItems()
    {
        return await _context.ContentItems.ToListAsync();
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ContentItem>> GetContentItem(int id)
    {
        var contentItem = await _context.ContentItems.FindAsync(id);

        if (contentItem == null)
        {
            return NotFound();
        }

        return contentItem;
    }

    [HttpPost]
    public async Task<ActionResult<ContentItem>> PostContentItem(ContentItemDto contentItemDto)
    {
        try
        {
            var contentItem = new ContentItem
            {
                Payload = JsonDocument.Parse(contentItemDto.Payload),
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.ContentItems.Add(contentItem);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetContentItem), new { id = contentItem.Id }, contentItem);
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, "Invalid JSON payload provided");
            return BadRequest("Invalid JSON payload");
        }
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> PutContentItem(int id, ContentItemDto contentItemDto)
    {
        var contentItem = await _context.ContentItems.FindAsync(id);
        if (contentItem == null)
        {
            return NotFound();
        }

        try
        {
            contentItem.Payload = JsonDocument.Parse(contentItemDto.Payload);
            contentItem.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, "Invalid JSON payload provided");
            return BadRequest("Invalid JSON payload");
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!ContentItemExists(id))
            {
                return NotFound();
            }
            throw;
        }

        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteContentItem(int id)
    {
        var contentItem = await _context.ContentItems.FindAsync(id);
        if (contentItem == null)
        {
            return NotFound();
        }

        _context.ContentItems.Remove(contentItem);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    private bool ContentItemExists(int id)
    {
        return _context.ContentItems.Any(e => e.Id == id);
    }
}

public class ContentItemDto
{
    public string Payload { get; set; } = string.Empty;
} 