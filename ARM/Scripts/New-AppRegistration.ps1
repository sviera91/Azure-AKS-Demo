#This script creates App Registration for AKS and adds access to ACR 

param
(
	[Parameter(Mandatory=$true)][string]$acrName,
	[Parameter(Mandatory=$true)][string]$acrResourceGroup,
	[Parameter(Mandatory=$true)][string]$envName,
	[Parameter(Mandatory=$true)][string]$envUse
)

#Variables
$spnName = "aks-spn-01"

#Looking for app registration
$spn = Get-AzureRmADApplication -DisplayNameStartWith $spnName -ErrorAction SilentlyContinue

#Functions to create app registration keys
function Create-AesManagedObject($key, $IV) {

    $aesManaged = New-Object "System.Security.Cryptography.AesManaged"
    $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
    $aesManaged.BlockSize = 128
    $aesManaged.KeySize = 256

    if ($IV) {
        if ($IV.getType().Name -eq "String") {
            $aesManaged.IV = [System.Convert]::FromBase64String($IV)
        }
        else {
            $aesManaged.IV = $IV
        }
    }

    if ($key) {
        if ($key.getType().Name -eq "String") {
            $aesManaged.Key = [System.Convert]::FromBase64String($key)
        }
        else {
            $aesManaged.Key = $key
        }
    }

    $aesManaged
}


function Create-AesKey() {
    $aesManaged = Create-AesManagedObject 
    $aesManaged.GenerateKey()
    [System.Convert]::ToBase64String($aesManaged.Key)
}



#Retrieving app ID
If ($spn -eq $null){

	#Create the 44-character key value

	$appKey = Create-AesKey

	$psadCredential = New-Object Microsoft.Azure.Commands.Resources.Models.ActiveDirectory.PSADPasswordCredential

	$startDate = Get-Date

	$psadCredential.StartDate = $startDate

	$psadCredential.EndDate = $startDate.AddYears(1)

	$psadCredential.KeyId = [guid]::NewGuid()

	$psadCredential.Password = $appKey

    Write-Host "There is no available app registration. A new app registration will be created."
	New-AzureRmADApplication -DisplayName $spnName -IdentifierUris "https://$spnName" -PasswordCredentials $psadCredential
	$appID = (Get-AzureRmADApplication -DisplayNameStartWith $spnName).ApplicationID

}else{

    Write-Host "We have encountered the app registration. Retrieving app ID."
	$appID = (Get-AzureRmADApplication -DisplayNameStartWith $spnName).ApplicationID

}

#Setting RBAC
$acrID = (Get-AzureRmContainerRegistry -name $acrName -ResourceGroupName "$acrResourceGroup-$envName-$envUse").ID
New-AzureRmRoleAssignment -ObjectId $appID -RoleDefinitionName "Reader" -Scope $acrID

#Setting VSTS variables
Write-Output ("##vso[task.setvariable variable=appID;]$appID")
[Environment]::SetEnvironmentVariable('appID', $appID, "Process")

Write-Output ("##vso[task.setvariable variable=appKey;]$appKey")
[Environment]::SetEnvironmentVariable('appKey', $appKey, "Process")