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

$TenantId = '40c5fbc4-e069-4526-9412-1d0cb5de4b0f'
$subscriptionId = '04e9d0e4-fbbc-4cf7-b59d-21ddd9a1fa30'
$ApplicationId = 'e48731a1-19a7-4cce-8bfe-6a7dbfc0f397'
$SecuredPassword = ConvertTo-SecureString -String '9FC8Q~V1BdnG1jsC9yTqb42C0BpWAQ1NCqrCsbJo' -AsPlainText -force

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