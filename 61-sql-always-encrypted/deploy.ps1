# Make sure to connect to your subscription using the following command
# Connect-AzAccount

# Create the resource group if not exists
if ($null -eq (Get-AzResourceGroup -Name 'az500' -ErrorAction SilentlyContinue)) {
   $resourceGroup = New-AzResourceGroup -Name 'Az500' -Location 'northeurope'  
}

# Defines the param values for the deployment. It sets the deployment name, the name of the resource group, and the path for the template file.
$inputObject = @{
    Name                  = 'az500-AlwaysEncrypted-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
    ResourceGroupName     = $resourceGroup.ResourceGroupName
    TemplateFile          = ".\azuredeploy.bicep"
}
    
# Make sure the resource group exists before running the command below.
New-AzResourceGroupDeployment @inputObject

