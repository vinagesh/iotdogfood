# Step 1 - Azure IoT dogfood resources
#### This ARM template creates all the necessary Azure resources to run a E2E IoT solution

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fvinagesh%2Fiotdogfood%2Fmain%2Fsetup.json)

# Step 2 - Run script
#### Currently some of the functionality is missing from ARM template deployments. This script is a way to fill in those gaps.
`
.\setup.ps1
`

# Step 3 - Azure IoT cloud app container deployment
#### This ARM tempalate creates an instace of the cloud app using a pre-existing container registry [dogfoodcloudapp](https://ms.portal.azure.com/#@microsoft.onmicrosoft.com/resource/subscriptions/d370e64f-339c-46fa-b9c2-da4a4c706ea0/resourceGroups/swIoTShow/providers/Microsoft.ContainerRegistry/registries/swickcontainers/repository) for the code in [DogfoodCloudApp](https://github.com/vinagesh/iotdogfood/tree/main/DogfoodCloudApp)

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fvinagesh%2Fiotdogfood%2Fmain%2Fcloudappcontainer.json)
