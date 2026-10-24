using System.Text;
using Newtonsoft.Json;

var currentDirectory = Directory.GetCurrentDirectory();
var storesDirectory = Path.Combine(currentDirectory, "stores");

var salesTotalDir = Path.Combine(currentDirectory, "salesTotalDir");
Directory.CreateDirectory(salesTotalDir);

var salesFiles = FindFiles(storesDirectory);

var salesTotal = CalculateSalesTotal(salesFiles);

// Keep the total from the original module (totals.txt)
File.AppendAllText(Path.Combine(salesTotalDir, "totals.txt"), $"{salesTotal}{Environment.NewLine}");

// New function: write the sales summary report
var reportPath = Path.Combine(salesTotalDir, "salesSummary.txt");
GenerateSalesSummary(salesFiles, storesDirectory, reportPath);

Console.WriteLine($"Report created: {reportPath}");
Console.WriteLine();
Console.WriteLine(File.ReadAllText(reportPath));

// ---------------------------------------------------------------

IEnumerable<string> FindFiles(string folderName)
{
    List<string> salesFiles = new List<string>();

    var foundFiles = Directory.EnumerateFiles(folderName, "*", SearchOption.AllDirectories);

    foreach (var file in foundFiles)
    {
        var extension = Path.GetExtension(file);
        if (extension == ".json" && Path.GetFileName(file).StartsWith("sales"))
        {
            salesFiles.Add(file);
        }
    }

    // sort so the report is always in the same order
    salesFiles.Sort(StringComparer.OrdinalIgnoreCase);
    return salesFiles;
}

double CalculateSalesTotal(IEnumerable<string> salesFiles)
{
    double salesTotal = 0;

    foreach (var file in salesFiles)
    {
        string salesJson = File.ReadAllText(file);
        SalesData? data = JsonConvert.DeserializeObject<SalesData?>(salesJson);

        salesTotal += data?.Total ?? 0;
    }

    return salesTotal;
}

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

record SalesData(double Total);
