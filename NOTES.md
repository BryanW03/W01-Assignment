# W01 Assignment Notes - Build .NET Applications with C#

Environment: .NET 8 LTS SDK

Project folders:
- `PizzaApi/` - web API with ASP.NET Core controllers (CRUD for pizzas)
- `SalesSummary/` - app that works with files and directories and creates the sales summary report

How to run:
- API: `cd PizzaApi && dotnet run --urls http://localhost:5100`
- Report: `cd SalesSummary && dotnet run`
- Evidence for the API (GET, POST, PUT, DELETE): `bash run-evidence.sh` (saves everything in `evidence.txt`)

> NOTE: Before you submit, run the commands above on your computer and paste your
> real output in the places marked **PASTE REAL OUTPUT**. The text I wrote under
> "Expected" is what the code should return.

---

## 1. Existing pizzas and my additional pizza

In `PizzaService.cs` I added a third pizza: **Pepperoni Supreme** (Id 3).

Request: `GET http://localhost:5100/pizza`

Expected response (status `200 OK`):

```json
[
  { "id": 1, "name": "Classic Italian", "isGlutenFree": false },
  { "id": 2, "name": "Veggie", "isGlutenFree": true },
  { "id": 3, "name": "Pepperoni Supreme", "isGlutenFree": false }
]
```

**PASTE REAL OUTPUT (or screenshot) HERE**

---

## 2. Request, response and status code for each operation

### GET
Request: `GET http://localhost:5100/pizza/3`

Expected response: status **200 OK**

```json
{ "id": 3, "name": "Pepperoni Supreme", "isGlutenFree": false }
```

### POST
Request: `POST http://localhost:5100/pizza`

```json
{ "name": "Hawaiian", "isGlutenFree": false }
```

Expected response: status **201 Created** (with header `Location: http://localhost:5100/Pizza/4`)

```json
{ "id": 4, "name": "Hawaiian", "isGlutenFree": false }
```

### PUT
Request: `PUT http://localhost:5100/pizza/2`

```json
{ "id": 2, "name": "Veggie Deluxe", "isGlutenFree": true }
```

Expected response: status **204 No Content** (empty body)

### DELETE
Request: `DELETE http://localhost:5100/pizza/1`

Expected response: status **204 No Content** (empty body)

**PASTE REAL OUTPUT FROM evidence.txt HERE**

---

## 3. Sales summary function (text copy)

```csharp
// Creates a text file with the total sales and the total of each file
void GenerateSalesSummary(IEnumerable<string> salesFiles, string storesFolder, string outputFile)
{
    double grandTotal = 0;
    var details = new StringBuilder();

    foreach (var file in salesFiles)
    {
        string salesJson = File.ReadAllText(file);
        SalesData? data = JsonConvert.DeserializeObject<SalesData?>(salesJson);

        double fileTotal = data?.Total ?? 0;
        grandTotal += fileTotal;

        // use the path inside "stores" so same file names do not get mixed
        string fileName = Path.GetRelativePath(storesFolder, file).Replace('\\', '/');
        details.AppendLine($"{fileName}: {fileTotal:C}");
    }

    var report = new StringBuilder();
    report.AppendLine("Sales Summary");
    report.AppendLine("----------------------------");
    report.AppendLine($"Total Sales: {grandTotal:C}");
    report.AppendLine();
    report.AppendLine("Details:");
    report.Append(details);

    File.WriteAllText(outputFile, report.ToString());
}
```



Total Sales: $38,832.71

Details:
201/sales.json: $22,385.32
202/sales.json: $9,631.14
203/sales.json: $5,812.50
204/sales/sales.json: $1,003.75