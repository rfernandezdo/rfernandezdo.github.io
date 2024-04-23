---
draft: true
date: 2024-04-24
authors:
  - rfernandezdo
categories:
    - Azure Services
tags:
    - Azure Resource Graph
    - 
---
# Azure Resource Graph

Azure Resource Graph is a service in Azure that is designed to extend Azure Resource Management by providing efficient and performant resource exploration with the ability to query at scale across a given set of subscriptions. 

## **What is Azure Resource Graph?**

Azure Resource Graph is a service that allows you to explore your Azure resources using a command-line tool or programmatically via an API. It provides immediate access to resource information, and the data is always up-to-date, making it an ideal tool for managing your Azure resources.

## **Key Features of Azure Resource Graph**

1. **Efficient Exploration**: Azure Resource Graph allows you to explore your Azure resources quickly and efficiently.
2. **Up-to-Date Information**: The data in Azure Resource Graph is always up-to-date, ensuring that you have the most accurate information about your resources.
3. **Powerful Querying**: Azure Resource Graph uses Kusto Query Language (KQL), which allows you to query your resources using a familiar SQL-like syntax.

## **Using Azure Resource Graph**

You can use Azure Resource Graph through the Azure portal, Azure CLI, or the Azure SDKs. Here's an example of how you might use Azure Resource Graph to retrieve all virtual machines in your subscriptions:

```bash
az graph query -q "where type =~ 'Microsoft.Compute/virtualMachines'"
```

This Azure CLI command will return a list of all virtual machines in your subscriptions.

## **Integrating Azure Resource Graph into Your Applications**

Azure Resource Graph provides a REST API that you can use to integrate resource querying into your applications. Microsoft also provides SDKs for several languages, including .NET, Java, JavaScript, and Python.

For instance, here's how you might call the Resource Graph API using the .NET SDK:

```csharp
Sure, I can provide a complete example of using Azure Resource Graph with the .NET SDK. 

This example assumes you have already installed and configured the `Microsoft.Azure.Management.ResourceGraph` NuGet package.

```csharp
using System;
using System.Threading.Tasks;
using Microsoft.Azure.Management.ResourceGraph;
using Microsoft.Azure.Management.ResourceGraph.Models;
using Microsoft.Rest.Azure.Authentication;

namespace AzureResourceGraphExample
{
    class Program
    {
        static async Task Main(string[] args)
        {
            // Authenticate with Azure
            var serviceCreds = await ApplicationTokenProvider.LoginSilentAsync(
                "{tenantId}", 
                "{clientId}", 
                "{clientSecret}");

            // Create a Resource Graph client
            var resourceGraphClient = new ResourceGraphClient(serviceCreds);

            // Create a query request
            var options = new QueryRequestOptions(resultFormat: ResultFormat.ObjectArray);
            var request = new QueryRequest("where type =~ 'Microsoft.Compute/virtualMachines'", options);

            // Execute the query
            var response = await resourceGraphClient.Resources(request);

            // Output the results
            foreach (var row in response.Data)
            {
                Console.WriteLine(row["name"]);
            }
        }
    }
}
```

In this code:

- Replace `{tenantId}`, `{clientId}`, and `{clientSecret}` with your Azure AD tenant ID, client ID, and client secret respectively.
- The `ApplicationTokenProvider.LoginSilentAsync` method is used to authenticate with Azure.
- The `ResourceGraphClient` object is used to interact with the Azure Resource Graph.
- A `QueryRequest` object is created with a Kusto query that retrieves all virtual machines.
- The `resourceGraphClient.Resources(request)` method is used to execute the query.
- Finally, the results are outputted to the console.


To launch this code, follow these steps:

1. **Create a new .NET Console Application:**
   Open your terminal and navigate to the directory where you want to create the project, then run the following command:
   
   ```bash
   dotnet new console -n AzureResourceGraphExample
   ```

2. **Navigate to the newly created project directory:**

   ```bash
   cd AzureResourceGraphExample
   ```

3. **Add the necessary NuGet package:**
   You need to add `Microsoft.Azure.Management.ResourceGraph` NuGet package to your project. Run the following command:

   ```bash
   dotnet add package Microsoft.Azure.Management.ResourceGraph --version 2.0.0
   ```

4. **Update Program.cs:**
   Open the `Program.cs` file in your preferred text editor or IDE (like Visual Studio Code or Visual Studio) and replace its content with the provided code. Remember to replace `{tenantId}`, `{clientId}`, and `{clientSecret}` with your actual values.

5. **Run the application:**
   Go back to your terminal and run the following command:

   ```bash
   dotnet run
   ```

This will compile and run your application. The results of the Resource Graph query will be printed to the console.

Remember that to run this example, you must have the .NET Core SDK installed on your machine. If you haven't installed it yet, you can download it from the [.NET website](https://dotnet.microsoft.com/download).

Also, ensure that the user represented by the `{clientId}` and `{clientSecret}` has the necessary permissions to access the resources and execute queries against the Azure Resource Graph.



## **Conclusion**

Azure Resource Graph is a powerful tool for managing your Azure resources. Its ability to provide up-to-date information and its powerful querying capabilities make it an essential tool for any Azure administrator or developer. Whether you're managing a few resources or thousands, Azure Resource Graph can help you keep track of your resources and understand their state.

## **References**

- [Azure Resource Graph documentation](https://docs.microsoft.com/en-us/azure/governance/resource-graph/overview)