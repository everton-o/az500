@description('The Windows version for Windows Jump-host VM.')
param windowsOSVersion string = '2016-Datacenter'

@description('Size for Windows jump-host VM')
param winVmSize string = 'Standard_D4_v3'

@description('Username for Windows jump-host VM')
param winVmUser string

@description('Password for Windows jump-host VM. The password must be between 6-72 characters long and must satisfy at least 3 of password complexity requirements from the following: 1) Contains an uppercase character 2) Contains a lowercase character 3) Contains a numeric digit 4) Contains a special character 5) Control characters are not allowed')
@secure()
param winVmPassword string

@description('DNS Label for Windows jump-host VM.')
param winVmDnsPrefix string

@allowed([
  'Yes'
  'No'
])
@description('Whether or not to deploy a VPN Gateway in the Hub')
param deployVpnGateway string = 'No'

@allowed([
  'Basic'
  'VpnGw1'
  'VpnGw2'
  'VpnGw3'
])
@description('The SKU of the Gateway, if deployed')
param gatewaySku string = 'Basic'

@description('Location for all resources.')
param location string = resourceGroup().location

var hubVnetName_var = 'hubVnet'
var hubVnetPrefix = '192.168.0.0/20'
var dmzSubnetName = 'DMZSubnet'
var dmzSubnetPrefix = '192.168.0.0/25'
var mgmtSubnetName = 'ManagementSubnet'
var mgmtSubnetPrefix = '192.168.1.0/24'
var sharedSubnetName = 'SharedSubnet'
var sharedSubnetPrefix = '192.168.4.0/22'
var gatewaySubnetName = 'GatewaySubnet'
var gatewaySubnetPrefix = '192.168.15.224/27'
var gatewayName_var = 'hubVpnGateway'
var gatewayPIPName_var = 'hubVpnGatewayPublicIp'
var subnetGatewayId = hubVnetName_gatewaySubnetName.id
var winJmphostName_var = 'winJmphostVm'
var devSpokeVnetName_var = 'spokeDevVnet'
var devSpokeVnetPrefix = '10.10.0.0/16'
var prodSpokeVnetName_var = 'spokeProdVnet'
var prodSpokeVnetPrefix = '10.100.0.0/16'
var spokeWorkloadSubnetName = 'WorkloadSubnet'
var devSpokeWorkloadSubnetPrefix = '10.10.0.0/16'
var prodSpokeWorkloadSubnetPrefix = '10.100.0.0/16'
var hubID = hubVnetName.id
var devSpokeID = devSpokeVnetName.id
var prodSpokeID = prodSpokeVnetName.id
var winVmNicName_var = '${winJmphostName_var}NIC'
var winVmStorageName_var = 'hubwinvm${uniqueString(resourceGroup().id)}'
var winNsgName_var = 'winJmpHostNsg'
var winJmphostPublicIpName_var = 'winJmphostVmPublicIp'

resource hubVnetName 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: hubVnetName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetPrefix
      ]
    }
    enableDdosProtection: false
    enableVmProtection: false
  }
}

resource hubVnetName_mgmtSubnetName 'Microsoft.Network/virtualNetworks/subnets@2019-11-01' = {
  parent: hubVnetName
  name: '${mgmtSubnetName}'
  properties: {
    addressPrefix: mgmtSubnetPrefix
  }
}

resource hubVnetName_sharedSubnetName 'Microsoft.Network/virtualNetworks/subnets@2019-11-01' = {
  parent: hubVnetName
  name: '${sharedSubnetName}'
  properties: {
    addressPrefix: sharedSubnetPrefix
  }
  dependsOn: [
    hubVnetName_mgmtSubnetName
  ]
}

resource hubVnetName_dmzSubnetName 'Microsoft.Network/virtualNetworks/subnets@2019-11-01' = {
  parent: hubVnetName
  name: '${dmzSubnetName}'
  properties: {
    addressPrefix: dmzSubnetPrefix
  }
  dependsOn: [
    hubVnetName_mgmtSubnetName
    hubVnetName_sharedSubnetName
  ]
}

resource hubVnetName_gatewaySubnetName 'Microsoft.Network/virtualNetworks/subnets@2019-11-01' = if (deployVpnGateway == 'Yes') {
  parent: hubVnetName
  name: '${gatewaySubnetName}'
  properties: {
    addressPrefix: gatewaySubnetPrefix
  }
  dependsOn: [
    hubVnetName_mgmtSubnetName
    hubVnetName_sharedSubnetName
    hubVnetName_dmzSubnetName
  ]
}

resource devSpokeVnetName 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: devSpokeVnetName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        devSpokeVnetPrefix
      ]
    }
    enableDdosProtection: false
    enableVmProtection: false
  }
}

resource devSpokeVnetName_spokeWorkloadSubnetName 'Microsoft.Network/virtualNetworks/subnets@2019-11-01' = {
  parent: devSpokeVnetName
  name: '${spokeWorkloadSubnetName}'
  properties: {
    addressPrefix: devSpokeWorkloadSubnetPrefix
  }
}

resource prodSpokeVnetName 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: prodSpokeVnetName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        prodSpokeVnetPrefix
      ]
    }
    enableDdosProtection: false
    enableVmProtection: false
  }
}

resource prodSpokeVnetName_spokeWorkloadSubnetName 'Microsoft.Network/virtualNetworks/subnets@2019-11-01' = {
  parent: prodSpokeVnetName
  name: '${spokeWorkloadSubnetName}'
  properties: {
    addressPrefix: prodSpokeWorkloadSubnetPrefix
  }
}

resource hubVnetName_gwPeering_hubVnetName_devSpokeVnetName 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-11-01' = if (deployVpnGateway == 'Yes') {
  parent: hubVnetName
  name: 'gwPeering_${hubVnetName_var}_${devSpokeVnetName_var}'
  location: location
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: devSpokeID
    }
  }
  dependsOn: [
    hubVnetName_mgmtSubnetName
    hubVnetName_sharedSubnetName
    hubVnetName_dmzSubnetName
    hubVnetName_gatewaySubnetName

    devSpokeVnetName_spokeWorkloadSubnetName
  ]
}

resource hubVnetName_peering_hubVnetName_devSpokeVnetName 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-11-01' = if (deployVpnGateway == 'No') {
  parent: hubVnetName
  name: 'peering_${hubVnetName_var}_${devSpokeVnetName_var}'
  location: location
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: devSpokeID
    }
  }
  dependsOn: [
    hubVnetName_mgmtSubnetName
    hubVnetName_sharedSubnetName
    hubVnetName_dmzSubnetName

    devSpokeVnetName_spokeWorkloadSubnetName
  ]
}

resource hubVnetName_gwPeering_hubVnetName_prodSpokeVnetName 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-11-01' = if (deployVpnGateway == 'Yes') {
  parent: hubVnetName
  name: 'gwPeering_${hubVnetName_var}_${prodSpokeVnetName_var}'
  location: location
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: prodSpokeID
    }
  }
  dependsOn: [
    hubVnetName_mgmtSubnetName
    hubVnetName_sharedSubnetName
    hubVnetName_dmzSubnetName
    hubVnetName_gatewaySubnetName

    prodSpokeVnetName_spokeWorkloadSubnetName
  ]
}

resource hubVnetName_peering_hubVnetName_prodSpokeVnetName 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-11-01' = if (deployVpnGateway == 'No') {
  parent: hubVnetName
  name: 'peering_${hubVnetName_var}_${prodSpokeVnetName_var}'
  location: location
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: prodSpokeID
    }
  }
  dependsOn: [
    hubVnetName_mgmtSubnetName
    hubVnetName_sharedSubnetName
    hubVnetName_dmzSubnetName

    prodSpokeVnetName_spokeWorkloadSubnetName
  ]
}

resource devSpokeVnetName_gwPeering_devSpokeVnetName_hubVnetName 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-11-01' = if (deployVpnGateway == 'Yes') {
  parent: devSpokeVnetName
  name: 'gwPeering_${devSpokeVnetName_var}_${hubVnetName_var}'
  location: location
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: hubID
    }
  }
  dependsOn: [
    hubVnetName_mgmtSubnetName
    hubVnetName_sharedSubnetName
    hubVnetName_dmzSubnetName
    hubVnetName_gatewaySubnetName

    devSpokeVnetName_spokeWorkloadSubnetName
    gatewayName
  ]
}

resource devSpokeVnetName_peering_devSpokeVnetName_hubVnetName 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-11-01' = if (deployVpnGateway == 'No') {
  parent: devSpokeVnetName
  name: 'peering_${devSpokeVnetName_var}_${hubVnetName_var}'
  location: location
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubID
    }
  }
  dependsOn: [
    hubVnetName_mgmtSubnetName
    hubVnetName_sharedSubnetName
    hubVnetName_dmzSubnetName

    devSpokeVnetName_spokeWorkloadSubnetName
  ]
}

resource prodSpokeVnetName_gwPeering_prodSpokeVnetName_hubVnetName 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-11-01' = if (deployVpnGateway == 'Yes') {
  parent: prodSpokeVnetName
  name: 'gwPeering_${prodSpokeVnetName_var}_${hubVnetName_var}'
  location: location
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: hubID
    }
  }
  dependsOn: [
    hubVnetName_mgmtSubnetName
    hubVnetName_sharedSubnetName
    hubVnetName_dmzSubnetName
    hubVnetName_gatewaySubnetName

    prodSpokeVnetName_spokeWorkloadSubnetName
    gatewayName
  ]
}

resource prodSpokeVnetName_peering_prodSpokeVnetName_hubVnetName 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2019-11-01' = if (deployVpnGateway == 'No') {
  parent: prodSpokeVnetName
  name: 'peering_${prodSpokeVnetName_var}_${hubVnetName_var}'
  location: location
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubID
    }
  }
  dependsOn: [
    hubVnetName_mgmtSubnetName
    hubVnetName_sharedSubnetName
    hubVnetName_dmzSubnetName

    prodSpokeVnetName_spokeWorkloadSubnetName
  ]
}

resource winJmphostName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: winJmphostName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: winVmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          diskSizeGB: 20
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    osProfile: {
      computerName: winJmphostName_var
      adminUsername: winVmUser
      adminPassword: winVmPassword
      windowsConfiguration: {
        provisionVMAgent: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: winVmNicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(winVmStorageName_var, '2019-06-01').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    winVmStorageName
  ]
}

resource winVmNicName 'Microsoft.Network/networkInterfaces@2019-11-01' = {
  name: winVmNicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'winJmpHostIpConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: winJmphostPublicIpName.id
          }
          subnet: {
            id: hubVnetName_mgmtSubnetName.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    networkSecurityGroup: {
      id: winNsgName.id
    }
    primary: true
  }
}

resource winNsgName 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: winNsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'NSG_RULE_INBOUND_RDP'
        properties: {
          description: 'Allow inbound RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
    defaultSecurityRules: [
      {
        name: 'AllowVnetInBound'
        properties: {
          description: 'Allow inbound traffic from all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInBound'
        properties: {
          description: 'Allow inbound traffic from azure load balancer'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 65001
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          description: 'Deny all inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowVnetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to all VMs in VNET'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 65000
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowInternetOutBound'
        properties: {
          description: 'Allow outbound traffic from all VMs to Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 65001
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny all outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 65500
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource winJmphostPublicIpName 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  name: winJmphostPublicIpName_var
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: toLower(winVmDnsPrefix)
    }
  }
}

resource winVmStorageName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  sku: {
    name: 'Standard_GRS'
    tier: 'Standard'
  }
  kind: 'Storage'
  name: winVmStorageName_var
  location: location
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: false
    encryption: {
      services: {
        file: {
          enabled: true
        }
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

resource gatewayPIPName 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: gatewayPIPName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource gatewayName 'Microsoft.Network/virtualNetworkGateways@2019-11-01' = if (deployVpnGateway == 'Yes') {
  name: gatewayName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetGatewayId
          }
          publicIPAddress: {
            id: gatewayPIPName.id
          }
        }
        name: 'vnetGatewayConfig'
      }
    ]
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
  }
}

output Jumphost_VM_IP_address string = winJmphostPublicIpName.properties.ipAddress