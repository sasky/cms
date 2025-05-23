using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;
using cms.Controllers;
using cms.Data;
using cms.Models;
using System.Text.Json;

namespace cms.Tests.Controllers;

public class ContentControllerTests : IDisposable
{
    private readonly CmsDbContext _context;
    private readonly ContentController _controller;
    private readonly Mock<ILogger<ContentController>> _mockLogger;

    public ContentControllerTests()
    {
        var options = new DbContextOptionsBuilder<CmsDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        _context = new CmsDbContext(options);
        _mockLogger = new Mock<ILogger<ContentController>>();
        _controller = new ContentController(_context, _mockLogger.Object);
    }

    [Fact]
    public async Task GetContentItems_ReturnsEmptyList_WhenNoItems()
    {
        // Act
        var result = await _controller.GetContentItems();

        // Assert
        var actionResult = Assert.IsType<ActionResult<IEnumerable<ContentItem>>>(result);
        var items = Assert.IsAssignableFrom<IEnumerable<ContentItem>>(actionResult.Value);
        Assert.Empty(items);
    }

    [Fact]
    public async Task GetContentItems_ReturnsAllItems_WhenItemsExist()
    {
        // Arrange
        var item1 = new ContentItem { Payload = JsonDocument.Parse("{\"test\":\"data1\"}") };
        var item2 = new ContentItem { Payload = JsonDocument.Parse("{\"test\":\"data2\"}") };

        _context.ContentItems.AddRange(item1, item2);
        await _context.SaveChangesAsync();

        // Act
        var result = await _controller.GetContentItems();

        // Assert
        var actionResult = Assert.IsType<ActionResult<IEnumerable<ContentItem>>>(result);
        var items = Assert.IsAssignableFrom<IEnumerable<ContentItem>>(actionResult.Value);
        Assert.Equal(2, items.Count());
    }

    [Fact]
    public async Task GetContentItem_ReturnsNotFound_WhenItemDoesNotExist()
    {
        // Act
        var result = await _controller.GetContentItem(999);

        // Assert
        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task GetContentItem_ReturnsItem_WhenItemExists()
    {
        // Arrange
        var item = new ContentItem { Payload = JsonDocument.Parse("{\"test\":\"data\"}") };
        _context.ContentItems.Add(item);
        await _context.SaveChangesAsync();

        // Act
        var result = await _controller.GetContentItem(item.Id);

        // Assert
        var actionResult = Assert.IsType<ActionResult<ContentItem>>(result);
        var returnedItem = Assert.IsType<ContentItem>(actionResult.Value);
        Assert.Equal(item.Id, returnedItem.Id);
    }

    [Fact]
    public async Task PostContentItem_CreatesItem_WithValidPayload()
    {
        // Arrange
        var dto = new ContentItemDto { Payload = "{\"name\":\"test\",\"value\":123}" };

        // Act
        var result = await _controller.PostContentItem(dto);

        // Assert
        var actionResult = Assert.IsType<ActionResult<ContentItem>>(result);
        var createdAtActionResult = Assert.IsType<CreatedAtActionResult>(actionResult.Result);
        var createdItem = Assert.IsType<ContentItem>(createdAtActionResult.Value);

        Assert.True(createdItem.Id > 0);
        Assert.NotNull(createdItem.Payload);

        // Verify item was saved to database
        var itemInDb = await _context.ContentItems.FindAsync(createdItem.Id);
        Assert.NotNull(itemInDb);
    }

    [Fact]
    public async Task PostContentItem_ReturnsBadRequest_WithInvalidJson()
    {
        // Arrange
        var dto = new ContentItemDto { Payload = "invalid json {" };

        // Act
        var result = await _controller.PostContentItem(dto);

        // Assert
        var actionResult = Assert.IsType<ActionResult<ContentItem>>(result);
        var badRequestResult = Assert.IsType<BadRequestObjectResult>(actionResult.Result);
        Assert.Equal("Invalid JSON payload", badRequestResult.Value);
    }

    [Fact]
    public async Task PutContentItem_UpdatesItem_WhenItemExists()
    {
        // Arrange
        var item = new ContentItem { Payload = JsonDocument.Parse("{\"original\":\"data\"}") };
        _context.ContentItems.Add(item);
        await _context.SaveChangesAsync();

        var dto = new ContentItemDto { Payload = "{\"updated\":\"data\"}" };

        // Act
        var result = await _controller.PutContentItem(item.Id, dto);

        // Assert
        Assert.IsType<NoContentResult>(result);

        // Verify item was updated
        var updatedItem = await _context.ContentItems.FindAsync(item.Id);
        Assert.NotNull(updatedItem);
        var payloadJson = updatedItem.Payload.RootElement.GetRawText();
        Assert.Contains("updated", payloadJson);
    }

    [Fact]
    public async Task PutContentItem_ReturnsNotFound_WhenItemDoesNotExist()
    {
        // Arrange
        var dto = new ContentItemDto { Payload = "{\"test\":\"data\"}" };

        // Act
        var result = await _controller.PutContentItem(999, dto);

        // Assert
        Assert.IsType<NotFoundResult>(result);
    }

    [Fact]
    public async Task PutContentItem_ReturnsBadRequest_WithInvalidJson()
    {
        // Arrange
        var item = new ContentItem { Payload = JsonDocument.Parse("{\"original\":\"data\"}") };
        _context.ContentItems.Add(item);
        await _context.SaveChangesAsync();

        var dto = new ContentItemDto { Payload = "invalid json {" };

        // Act
        var result = await _controller.PutContentItem(item.Id, dto);

        //  Assert
        var badRequestResult = Assert.IsType<BadRequestObjectResult>(result);
        Assert.Equal("Invalid JSON payload", badRequestResult.Value);
    }

    [Fact]
    public async Task DeleteContentItem_RemovesItem_WhenItemExists()
    {
        // Arrange
        var item = new ContentItem { Payload = JsonDocument.Parse("{\"test\":\"data\"}") };
        _context.ContentItems.Add(item);
        await _context.SaveChangesAsync();

        // Act
        var result = await _controller.DeleteContentItem(item.Id);

        // Assert
        Assert.IsType<NoContentResult>(result);

        // Verify item was deleted
        var deletedItem = await _context.ContentItems.FindAsync(item.Id);
        Assert.Null(deletedItem);
    }

    [Fact]
    public async Task DeleteContentItem_ReturnsNotFound_WhenItemDoesNotExist()
    {
        // Act
        var result = await _controller.DeleteContentItem(999);

        // Assert
        Assert.IsType<NotFoundResult>(result);
    }

    public void Dispose()
    {
        _context.Dispose();
    }
}