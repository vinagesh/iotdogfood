param userPrincipalId string {
  metadata: {
    description: 'The user user principal Id. Ex: username.microsoft.com'
  }
}

var roleAssignmentName = '90a6a1c4-290e-4e76-b20e-428c3796c37e'
var KeyVaultName = '${resourceGroup().name}-d-kv'
var HubName = '${resourceGroup().name}-d-hub'
var DpsName = '${resourceGroup().name}-d-dps'
var TsiName = '${resourceGroup().name}-d-tsi'
var TsiStorageAccountName = '${resourceGroup().name}dstorage'
var AzureMapsAccountName = '${resourceGroup().name}-d-maps'

resource iotHub 'Microsoft.Devices/IotHubs@2020-08-01' = {
  name: HubName
  location: resourceGroup().location
  properties: {
    routing: {
      fallbackRoute: {
        name: '$fallback'
        source: 'DeviceMessages'
        isEnabled: true
        endpointNames: [
          'events'
        ]
      }
      routes: [
        {
          name: 'deviceLifecycle'
          source: 'DeviceLifecycleEvents'
          isEnabled: true
          endpointNames: [
            'events'
          ]
        }
        {
          name: 'digitalTwinChanges'
          source: 'DigitalTwinChangeEvents'
          isEnabled: true
          endpointNames: [
            'events'
          ]
        }
        {
          name: 'deviceTwinChanges'
          source: 'TwinChangeEvents'
          isEnabled: true
          endpointNames: [
            'events'
          ]
        }
      ]
    }
  }
  sku: {
    name: 'S1'
    capacity: 1
  }
}

resource appConsumerGroup 'Microsoft.Devices/IotHubs/eventHubEndpoints/ConsumerGroups@2020-03-01' = {
  name: '${iotHub.name}/events/serviceapp'
  properties: {
  }
}

var tsiGroupName = 'tsi'
resource tsiConsumerGroup 'Microsoft.Devices/IotHubs/eventHubEndpoints/ConsumerGroups@2020-03-01' = {
  name: '${iotHub.name}/events/${tsiGroupName}'
  properties: {
  }
}

resource dps 'Microsoft.Devices/provisioningServices@2017-11-15' = {
  name: DpsName
  location: resourceGroup().location
  sku: {
    name: 'S1'
    capacity: 1
  }
  properties: {
    iotHubs: [
      {
        location: resourceGroup().location
        connectionString: 'HostName=${iotHub.name}.azure-devices.net;SharedAccessKeyName=iothubowner;SharedAccessKey=${listkeys(hubKeysId, '2020-01-01').primaryKey}'
      }
    ]
  }
}

var userIdentityName = 'userIdentity'
resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${userIdentityName}'
  location: resourceGroup().location
}

var ownerRoleDefinitionId = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
resource userIdentityRoleAssignment 'Microsoft.Authorization/roleAssignments@2018-09-01-preview' = {
  name: '${roleAssignmentName}'
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${contriburorRoleDefinitionId}'
    principalId: '${reference(userIdentity.id, '2018-11-30').principalId}'
    principalType: 'ServicePrincipal'
  }
}

var groupEnrollmentId = 'weatherstations'
resource enrollmentGroupCreationScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'createDpsEnrollmentGroup'
  kind: 'AzureCLI'
  location: resourceGroup().location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userIdentity.id}' : {}
    }
  }
  properties: {
    azCliVersion: '2.9.1'
    retentionInterval: 'P1D'
    scriptContent: 'az extension add --name azure-iot; az iot dps enrollment-group create -g ${resourceGroup().name} --dps-name ${dps.name} --enrollment-id ${groupEnrollmentId}'
  }
  dependsOn:[
    userIdentityRoleAssignment
  ]
}

resource keyVaultAccessPoicyCreationScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'setKeyVaultAccessPolicy'
  kind: 'AzureCLI'
  location: resourceGroup().location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userIdentity.id}' : {}
    }
  }
  properties: {
    azCliVersion: '2.9.1'
    retentionInterval: 'P1D'
    scriptContent: 'az keyvault set-policy -n ${KeyVaultName} --secret-permissions get list set --upn ${userPrincipalId}'
  }
  dependsOn:[
    userIdentityRoleAssignment
    keyVault
  ]
}

resource tsiStorageAccount 'Microsoft.Storage/storageAccounts@2018-02-01' = {
  name: TsiStorageAccountName
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: { 
    isHnsEnabled: false
  }
}

resource tsi 'Microsoft.TimeSeriesInsights/environments@2020-05-15' = {
  name: TsiName
  location: resourceGroup().location
  kind: 'Gen2'
  sku: {
    name:'L1'
    capacity: 1
  }
  properties: {
    storageConfiguration: {
      accountName: tsiStorageAccount.name
      managementKey: '${listkeys(tsiStorageAccount.id, '2018-02-01').keys[0].value}'
    }
    timeSeriesIdProperties: [
      {
        name: 'iothub-connection-device-id'
        type: 'String'
      }
    ]
  }
}

resource tsiReaderAccessPolicy 'Microsoft.TimeSeriesInsights/environments/accessPolicies@2020-05-15' = {
  name: '${tsi.name}/readerAccessPolicy1'
  properties: {
    principalObjectId: userPrincipalId
    roles: [
      'Reader'
    ]
  }
}

var hubKeysId = resourceId('Microsoft.Devices/IotHubs/Iothubkeys', HubName, 'iothubowner')
resource tsiEventSource 'Microsoft.TimeSeriesInsights/environments/eventsources@2020-05-15' = {
  name: '${tsi.name}/dogfoodsource'
  kind: 'Microsoft.IoTHub'
  location: resourceGroup().location
  properties: {
    iotHubName: iotHub.name
    consumerGroupName: tsiGroupName
    eventSourceResourceId: iotHub.id
    keyName: 'iothubowner'
    sharedAccessKey: '${listkeys(hubKeysId, '2019-11-04').primaryKey}'
    timestampPropertyName: 'iothub-connection-device-id'
  }
  dependsOn: [
    tsiConsumerGroup
  ]
}

resource azureMaps 'Microsoft.Maps/accounts@2020-02-01-preview' = {
  name: AzureMapsAccountName
  location: 'global'
  sku: {
    name: 'S0'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2018-02-14' = {
  name: KeyVaultName
  location: resourceGroup().location
    properties: {    
    enabledForDeployment: false
    enabledForTemplateDeployment: false
    enabledForDiskEncryption: false
    accessPolicies: [
    ]
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    enableSoftDelete: false
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
      ipRules: [
      ]
      virtualNetworkRules: [
      ]
    }
  }
}

resource iotHubConnectionString 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: concat('${keyVault.name}', '/IotHubConnectionString')
  properties: {
    value: 'HostName=${iotHub.name}.azure-devices.net;SharedAccessKeyName=iothubowner;SharedAccessKey=${listkeys(hubKeysId, '2019-11-04').primaryKey}'
  }
}

resource eventHubEndpoint 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: concat('${keyVault.name}', '/EventHubEndpoint')
  properties: {
    value: '${iotHub.properties.eventHubEndpoints.events.endpoint}'
  }
}

resource eventHubPath 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: concat('${keyVault.name}', '/EventHubPath')
  properties: {
    value: '${iotHub.properties.eventHubEndpoints.events.path}'
  }
}

var eventHubKeysId = resourceId('Microsoft.Devices/IotHubs/Iothubkeys', HubName, 'service')
resource eventHubKey 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: concat('${keyVault.name}', '/EventHubKey')
  properties: {
    value: '${listkeys(eventHubKeysId, '2019-11-04').primaryKey}'
  }
}

resource dpsScopeId 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: concat('${keyVault.name}', '/DpsScopeId')
  properties: {
    value: '${dps.properties.idScope}'
  }
}

var dpsKeysId = resourceId('Microsoft.Devices/ProvisioningServices/keys', DpsName, 'provisioningserviceowner')
resource dpsPrimaryKey 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: concat('${keyVault.name}', '/DpsPrimaryKey')
  properties: {
    value: '${listkeys(dpsKeysId, '2017-11-15').primaryKey}'
  }
}

var azureMapsKeysId = resourceId('Microsoft.Maps/accounts', AzureMapsAccountName)
resource azureMapsPrimaryKey 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: concat('${keyVault.name}', '/AzureMapsPrimaryKey')
  properties: {
    value: '${listkeys(azureMapsKeysId, '2020-02-01-preview').primaryKey}'
  }
}

var containerRegistryPasswordId = '/subscriptions/d370e64f-339c-46fa-b9c2-da4a4c706ea0/resourceGroups/swIoTShow/providers/Microsoft.ContainerRegistry/registries/swickcontainers'
resource containerRegistryPassword 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: concat('${keyVault.name}', '/ContainerRegistryPassword')
  properties: {
    value: '${listCredentials(containerRegistryPasswordId, '2017-10-01').passwords[0].value}'
  }
}