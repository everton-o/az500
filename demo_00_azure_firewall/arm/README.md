# Hub and Spoke Topology Sandbox

This template creates a basic hub-and-spoke topology setup. It creates a Hub VNet with subnets DMZ, Management, Shared and Gateway (optionally), with two Spoke VNets, development and production, containing a workload subnet each. It also deploys a Windows Jump-Host on the Management subnet of the HUB, and establishes VNet peerings between the Hub and the two spokes. 

Note that if you choose to deploy the VPN gateway, it may take up to 45 minutes to complete.


[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https://raw.githubusercontent.com/everton-o/az500/main/demo_00_azure_firewall/arm/azuredeploy.json)
