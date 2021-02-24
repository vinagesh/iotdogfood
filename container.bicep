param HubName string {
  metadata: {
    description: 'The name of the main IoT hub instance.'
  }
}

param CloudAppContainerName string {
  default: '${resourceGroup().name}-d-cloudapp'
  metadata: {
    description: 'The name of the conatiner instance.'
  }
}

param CloudAppDnsName string {
  default: '${resourceGroup().name}-d-cloudapp'
  metadata: {
    description: 'The dns name of the conatiner instance.'
  }
}

param RegistryServer string {
  default: 'swickcontainers.azurecr.io'
  metadata: {
    description: 'The container registry login server.'
  }
}

param RegistryServerUserName string {
  default: 'swickcontainers'
  metadata: {
    description: 'The container registry login server user name.'
  }
}

param RegistryServerPassword string {
  secure: true
  metadata: {
    description: 'The container registry login server password.'
  }
}

param CloudAppContainerImageName string {
  default: 'swickcontainers.azurecr.io/dogfoodcloudapp:latest'
  metadata: {
    description: 'The container registry login server password.'
  }
}

var hubKeysId = resourceId('Microsoft.Devices/IotHubs/Iothubkeys', HubName, 'iothubowner')
resource container 'Microsoft.ContainerInstance/containerGroups@2019-12-01' = {
  name: CloudAppContainerName
  location: resourceGroup().location
  properties: {    
    containers: [
      {        
        name: CloudAppContainerName
        properties: {
          image: '${CloudAppContainerImageName}'
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 1
            }
          }                        
          ports: [
            {
              port: 80
              protocol: 'TCP'
            }
          ] 
          environmentVariables: [
            {
              name: 'IotHubConnectionString'
              value: 'HostName=${HubName}.azure-devices.net;SharedAccessKeyName=iothubowner;SharedAccessKey=${listkeys(hubKeysId, '2019-11-04').primaryKey}'
            }
          ]
        }        
      }
    ]
    restartPolicy: 'OnFailure'
    imageRegistryCredentials: [
      {
        server: '${RegistryServer}'
        username: '${RegistryServerUserName}'
        password: RegistryServerPassword
      }
    ]
    ipAddress: {
      type: 'Public'
      ports: [
        {
          port: 80
          protocol: 'TCP'
        }
      ]
      dnsNameLabel: CloudAppDnsName
    }
    osType: 'Linux'
  }  
}
