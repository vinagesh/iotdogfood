using DogfoodCloudApp;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Devices;
using Newtonsoft.Json;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace DogFoodCloudApp.Controllers
{
    [Route("[controller]")]
    [ApiController]
    public class DevicesController : ControllerBase
    {
        private static RegistryManager _registryManager;

        static DevicesController()
        {
            _registryManager = RegistryManager.CreateFromConnectionString(Settings.Instance.IotHubConnectionString); 
        }

        [HttpGet]
        public async Task<IEnumerable<Device>> GetDevicesAsync(CancellationToken cancellationToken = default)
        {
            IQuery query = _registryManager.CreateQuery("select * from devices");
            List<Device> devices = new List<Device>();
            while(query.HasMoreResults)
            {
                IEnumerable<string> devicePage = await query.GetNextAsJsonAsync().ConfigureAwait(false);
                foreach(var device in devicePage)
                {
                    devices.Add(JsonConvert.DeserializeObject<Device>(device));
                }
            }
            return devices;
        }
    }
}
