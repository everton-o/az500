

@description('Name of the virtual network')
param vnetName string = 'vnet-001'

@description('VNet Address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('subnet name')
param subnetName1 string = 'dns-subnet-10.0.0.0-24'

@description('subnet address prefix')
param subnetAddressPrefix1 string = '10.0.0.0/24'

@description('subnet name 2')
param subnetName2 string = 'data-subnet-10.0.1.0-24'

@description('subnet address prefix 2')
param subnetAddressPrefix2 string = '10.0.1.0/24'

@description('user to access the VMs')
param adminUsername string

@description('password to access the VMs')
@secure()
param adminPassword string

var location = resourceGroup().location




resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: uniqueString('storage', resourceGroup().id)
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}


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
        name: subnetName2
        properties: {
          addressPrefix: subnetAddressPrefix2
        }
      }
    ]
  }
}


// deploy public ip 01
resource publicIp 'Microsoft.Network/publicIPAddresses@2022-01-01' = [for i in range(0, 2): {
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
resource networkCard 'Microsoft.Network/networkInterfaces@2021-02-01' = [for i in range(0, 2):  {
  name: i == 0 ? 'dns-nic' : 'data-nic' 
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
  dependsOn: [
    publicIp
  ]
}]


// Deploy Windows VM
resource windowsVM 'Microsoft.Compute/virtualMachines@2020-12-01' = [for i in range(0, 2): {
  name: i == 0 ? 'dns-win22' : 'data-win22'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: i == 0 ? 'dns-win22' : 'data-win22'
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


// Install softwares required for VM to work as a custom DevOps agent
resource CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: 'dns-win22/CustomScriptExtension'
  location: location
  dependsOn: [
    windowsVM
  ]
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true                            
    protectedSettings: { 
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File .\\install-dns.ps1'
        fileUris: [
        'https://raw.githubusercontent.com/everton-o/az500/main/30-implement-azure-private-endpoints/tools/install-dns.ps1'                 
      ]
    }           
  }
}
