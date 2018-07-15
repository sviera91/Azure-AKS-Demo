#This script creates public IP for AKS

param
(
	[Parameter(Mandatory=$true)][string]$aksResourceGroup,
	[Parameter(Mandatory=$true)][string]$aksName,
	[Parameter(Mandatory=$true)][string]$region,
	[Parameter(Mandatory=$true)][string]$envName,
	[Parameter(Mandatory=$true)][string]$envUse
)

#Variables
$pipName = "$aksName-pip"

$RG = "MC_$($aksResourceGroup)-$($envName)-$($envUse)_$($aksName)_$($region)"

#Looking for public IP address
$PIP = Get-AzureRmPublicIpAddress -Name $pipName -ResourceGroupName $RG -ErrorAction SilentlyContinue

#Retrieving IP address value
If ($PIP -eq $null){

    Write-output "There is no available public IP. A new public IP address will be created."
	New-AzureRmPublicIpAddress -Name $pipName -ResourceGroupName $RG -AllocationMethod Static -DomainNameLabel $pipName -Location $region -Sku Basic 
	$pipValue = (Get-AzureRmPublicIpAddress -Name $pipName -ResourceGroupName $RG).IpAddress


}else{

    Write-output "We have encountered a public IP address. Retrieving address."
	$pipValue = (Get-AzureRmPublicIpAddress -Name $pipName -ResourceGroupName $RG).IpAddress

}

#Setting VSTS variable
Write-Output ("##vso[task.setvariable variable=pipValue;]$pipValue")
[Environment]::SetEnvironmentVariable('pipValue', $pipValue, "Process")