<#
    Author: Everton Oliveira
    Description: Basic installation of DNS server with forwarder set to Azure DNS servers. 
#>


##Install DNS Server
Install-WindowsFeature DNS -IncludeManagementTools

##Add Forwarder to Azure, by default this simply forwards DNS queries to Azure.
Add-DnsServerForwarder -IPAddress 168.63.129.16 -PassThru
