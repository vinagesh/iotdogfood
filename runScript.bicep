resource runscript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'enablesecurity'
  kind: 'AzureCLI'
  location: resourceGroup().location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/53cd450b-b108-4e6e-b048-f63c1dcc8c8f/resourcegroups/vinagesh-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/vinagesh-test-msi' : {}
    }
  }
  properties: {
    azCliVersion: '2.9.1'
    retentionInterval: 'P1D'
    primaryScriptUri: 'https://raw.githubusercontent.com/vinagesh/iotdogfood/main/script.ps1'  
  }
}