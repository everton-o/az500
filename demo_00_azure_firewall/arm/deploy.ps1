# # Make sure we're on right path
# Set-Location $PSScriptRoot

# # Log in on Azure
# Connect-AzAccount

# # Get desired subscription
# $Subscriptions = Get-AzSubscription -WarningAction SilentlyContinue
# $subChoice = $Subscriptions | out-gridview -Title "Select One or More Subscriptions" -PassThru
# Set-AzContext $subChoice.Id

# # create new resource group
# $rg = (New-AzResourceGroup -Name 'hubspoke-rg' -Location 'northeurope').ResourceGroupName

# Deploy resource
New-AzResourceGroupDeployment `
    -Name 'deploy01' `
    -ResourceGroupName 'hubspoke-rg' `
    -TemplateFile $PSScriptRoot\azuredeploy.json `
    -TemplateParameterFile $PSScriptRoot\azuredeploy.parameters.json



