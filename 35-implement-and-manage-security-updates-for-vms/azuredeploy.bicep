

@description('Name of the virtual network')
param vnetName string = 'vnet-001'

@description('VNet Address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('subnet name')
param subnetName1 string = 'data-subnet-10.0.1.0-24'

@description('subnet address prefix')
param subnetAddressPrefix1 string = '10.0.1.0/24'

@description('user to access the VMs')
param adminUsername string

@description('password to access the VMs')
@secure()
param adminPassword string

var location = resourceGroup().location

var resourceCount = 1


// deploy log analytics 
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: uniqueString('loganalytics', resourceGroup().id)
  location: location
}


// deploy automation accounts
resource automationAccount 'Microsoft.Automation/automationAccounts@2021-06-22' = {
  name: uniqueString('automation', resourceGroup().id)
  location: location
}


// deploy virtual network
resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName1
        properties: {
          addressPrefix: subnetAddressPrefix1
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.0.0/26'
        }
      }
    ]
  }
}


// deploy public ip 01
resource publicIp 'Microsoft.Network/publicIPAddresses@2022-01-01' = [for i in range(0, resourceCount): {
  name: 'public_ip_0${i}'
  location: location
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}]


// Deploy Network Interface Card
resource networkCard 'Microsoft.Network/networkInterfaces@2021-02-01' = [for i in range(0, resourceCount):  {
  name: 'nic-data-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', 'public_ip_0${i}')
          }
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnet.properties.subnets[i].id
          }
        }
      }
    ]
  }
}]


// Deploy Windows VM
resource windowsVM 'Microsoft.Compute/virtualMachines@2020-12-01' = [for i in range(0, resourceCount): {
  name: 'vm-data${i}-${substring(uniqueString(resourceGroup().id),0,5)}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'win-0${i}-data'
      adminUsername: adminUsername
      adminPassword: adminPassword
      allowExtensionOperations: true
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: false
        patchSettings: {}
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        name: toLower('osdisk-${i}vm${substring(uniqueString(resourceGroup().id), 0 ,10)}')
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkCard[i].id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false        
      }
    }
  }
}]
