# # Make sure we're on right path
# Set-Location $PSScriptRoot

# # Log in on Azure
# Connect-AzAccount

# # Get desired subscription
# $Subscriptions = Get-AzSubscription -WarningAction SilentlyContinue
# $subChoice = $Subscriptions | out-gridview -Title "Select One or More Subscriptions" -PassThru
# Set-AzContext $subChoice.Id

# create new resource group if not exists
$rg = Get-AzResourceGroup -name 'huspoke-rg' -ErrorAction SilentlyContinue
if(!$rg) {
    $rg = New-AzResourceGroup -Name 'huspoke-rg' -Location 'northeurope'
}

# Deploy resource
New-AzResourceGroupDeployment `
    -Name 'deploy01' `
    -ResourceGroupName $rg.ResourceGroupName `
    -TemplateFile $PSScriptRoot\azuredeploy.json `
    -TemplateParameterFile $PSScriptRoot\azuredeploy.parameters.json



