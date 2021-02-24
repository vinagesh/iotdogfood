using Microsoft.AspNetCore.Mvc;
using System.Linq;
using System.Threading.Tasks;

namespace DogfoodCloudApp.Controllers
{
    [Route("[controller]")]
    [ApiController]
    public class IotHubNameController : ControllerBase
    {
        [HttpGet]
        public string GetIotHubName()
        {
            var csParts = Settings.Instance.IotHubConnectionString.Split(';');
            var hostNamePart = csParts.Where(part => part.StartsWith("HostName="));
            var hostnameParts = hostNamePart.First().Split('=')[1];            
            return hostnameParts.Split('.')[0];
        }
    }
}
