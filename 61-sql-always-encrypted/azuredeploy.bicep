
@description('The name of the SQL logical server.')
param serverName string = uniqueString('sql', resourceGroup().id)

@description('The administrator username of the SQL logical server.')
param administratorLogin string

@description('The administrator password of the SQL logical server.')
@secure()
param administratorLoginPassword string

@description('Random value to generate unique name to services')
param uniqueValue string = newGuid()

var keyVaultName = 'kv-${uniqueString(uniqueValue,resourceGroup().id)}'
var location = resourceGroup().location


// deploy virtual sql server
resource sqlServer 'Microsoft.Sql/servers@2021-08-01-preview' = {
  name: serverName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
}

// deploy sql database
resource sqlDB 'Microsoft.Sql/servers/databases@2021-08-01-preview' = {
  parent: sqlServer
  name: 'ContosoHR'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

// deploy key vault
resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name:'standard'
    }
    accessPolicies: []
  }
}



