<#
    Author: Everton Oliveira
    Description: Request token from service principal, list and create resource group on subscription
#>

##**********************
# Requirements: Az module
##**********************

# if (-not (Get-Module -name Az -ListAvailable)) {
#     Install-Module -Name "Az" -scope AllUsers
# }


#**********************
# LOGIN AS A SERVICE PRINCIPAL
#**********************

$TenantId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
$subscriptionId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
$ApplicationId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
$SecuredPassword = ConvertTo-SecureString -String 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -AsPlainText -force

$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationId, $SecuredPassword
Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential -Subscription $subscriptionId


#**********************
# GET TOKEN FOR SERVICE PRINCIPAL
#**********************

$token = (Get-AzAccessToken).Token
$authHeader = @{
    'Content-Type' = 'application/json'
     Authorization = 'Bearer ' + $token
}


#**********************
# GET RESOURCE GROUPS
#**********************

$uri = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups?api-version=2014-04-01"

# get all resource groups created on the subscription response
$res = Invoke-WebRequest -UseBasicParsing -Uri $URI -Method GET -Headers $authHeader

# parse resource group names
($res.Content | ConvertFrom-Json).value


#**********************
# ADD RESOURCE GROUPS
#**********************

$resourceGroupName = 'myRestResourceGroupAz500'
$uri = "https://management.azure.com/subscriptions/$($subscriptionId)/resourcegroups/$($resourceGroupName)?api-version=2020-09-01"

# get all resource groups created on the subscription response
$res = Invoke-WebRequest -UseBasicParsing -Uri $URI -Method PUT -Headers $authHeader

# parse resource group names
($res.Content | ConvertFrom-Json).value