var userIdentityName = 'userIdentity'
resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${userIdentityName}'
  location: resourceGroup().location
}

var roleAssignmentName = guid(resourceGroup().name)
var ownerRoleDefinitionId = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
resource userIdentityRoleAssignment 'Microsoft.Authorization/roleAssignments@2018-09-01-preview' = {
  name: '${roleAssignmentName}'
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${ownerRoleDefinitionId}'
    principalId: '${reference(userIdentity.id, '2018-11-30').principalId}'
    principalType: 'ServicePrincipal'
  }
}

resource runscript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'enablesecurity'
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