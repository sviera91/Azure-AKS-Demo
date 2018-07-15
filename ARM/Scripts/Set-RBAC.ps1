#This script creates App Registration for AKS and adds access to ACR 

param
(
	[Parameter(Mandatory=$true)][string]$acrName,
	[Parameter(Mandatory=$true)][string]$acrResourceGroup,
	[Parameter(Mandatory=$true)][string]$envName,
	[Parameter(Mandatory=$true)][string]$envUse,
	[Parameter(Mandatory=$true)][string]$aksSpnObjId
)

#Variables
$spnName = "aks-spn-01"

#Setting RBAC
#Remove Assignment if already exists
$roleExists = Get-AzureRmRoleAssignment -ObjectId $aksSpnObjId -RoleDefinitionName "reader" -ResourceGroupName "$acrResourceGroup-$envName-$envUse"

If($roleExists)
    {
        Write-Verbose "Role assignment already exists, continuing..."
    }
else{
        New-AzureRmRoleAssignment -ObjectId $aksSpnObjId -RoleDefinitionName "reader" -ResourceGroupName "$acrResourceGroup-$envName-$envUse"
    }