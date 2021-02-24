using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace DogfoodCloudApp
{
    public class Settings
    {
        public static Settings Instance = new Settings();

        public void Initialize()
        {
            IotHubConnectionString = Environment.GetEnvironmentVariable("IotHubConnectionString");
        }

        public string IotHubConnectionString { get; private set; }
    }
}
