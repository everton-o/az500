@description('Admin username for the backend servers')
@secure()
param adminUsername string = 'xxxxxxxxx'

@description('Password for the admin account on the backend servers')
@secure()
param adminPassword string = 'xxxxxxxxxxxxxxxxxxx'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Size of the virtual machine.')
param vmSize string = 'Standard_B2ms'

var virtualMachineName = 'myVM'
var virtualNetworkName_var = 'myVNet'
var networkInterfaceName = 'net-int'
var ipconfigName = 'ipconfig'
var publicIPAddressName = 'public_ip'
var nsgName = 'vm-nsg'
var virtualNetworkPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var backendSubnetPrefix = '10.0.1.0/24'



resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: virtualNetworkName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkPrefix
      ]
    }
    subnets: [
      {
        name: 'myAGSubnet'
        properties: {
          addressPrefix: subnetPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'myBackendSubnet'
        properties: {
          addressPrefix: backendSubnetPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
    enableVmProtection: false
  }
}


resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-05-01' = [for i in range(0, length(range(0, 2))): {
  name: '${nsgName}${(range(0, 2)[i] + 1)}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
        }
      }
    ]
  }
}]


resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2021-05-01' = [for i in range(0, length(range(0, 3))): {
  name: '${publicIPAddressName}${range(0, 3)[i]}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}]



resource networkCard 'Microsoft.Network/networkInterfaces@2021-02-01' = [for i in range(0, length(range(0, 2))): {
  name: '${networkInterfaceName}${(range(0, 2)[i] + 1)}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${ipconfigName}${(range(0, 2)[i] + 1)}'
        properties: {
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', '${publicIPAddressName}${(range(0, 2)[i] + 1)}')
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, 'myBackendSubnet')
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    networkSecurityGroup: {
        id: resourceId('Microsoft.Network/networkSecurityGroups', '${nsgName}${(range(0, 2)[i] + 1)}')
    }
  }
  dependsOn: [
    vnet
    publicIPAddress
    networkSecurityGroup
  ]
}]


resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = [for i in range(0, length(range(0, 2))): {
  name: '${virtualMachineName}${(range(0, 2)[i] + 1)}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2016-Datacenter'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        diskSizeGB: 127
      }
    }
    osProfile: {
      computerName: '${virtualMachineName}${(range(0, 2)[i] + 1)}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${networkInterfaceName}${(range(0, 2)[i] + 1)}')
        }
      ]
    }
  }
  dependsOn: [
    networkCard
  ]
}]



// Install softwares required for VM to work
resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [for i in range(0, length(range(0, 2))): {
  name: '${virtualMachineName}${(range(0, 2)[i] + 1)}/IIS'
  location: location
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.4'
    settings: {
      commandToExecute: 'powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path "C:\\inetpub\\wwwroot\\Default.htm" -Value $($env:computername)'
    }
  }
  dependsOn: [
    vm
  ]
}]






  
