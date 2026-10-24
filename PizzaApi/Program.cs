var builder = WebApplication.CreateBuilder(args);

// Add controllers to the app
builder.Services.AddControllers();

var app = builder.Build();

app.MapControllers();

app.Run();
