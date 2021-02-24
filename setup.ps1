
param(
    [Parameter(Mandatory)]
    [string] $ResourceGroup,
    
    [Parameter()]
    [string] $DpsName,

    [Parameter()]
    [string] $KeyVaultName
)

$keyVaultName = $KeyVaultName
if (-not $keyVaultName)
{
    $keyVaultName = $ResourceGroup+'-d-kv'
}

$dpsName = $DpsName
if (-not $dpsName)
{
    $dpsName = $ResourceGroup+'-d-dps'
}

# Create enrollment group and store the primary key in keyvault
$groupEnrollmentId = "weatherstations"
$groupEnrollmentExists = az iot dps enrollment-group list -g $ResourceGroup --dps-name $dpsName --query "[?enrollmentGroupId=='$groupEnrollmentId'].enrollmentGroupId" --output tsv
if (-not $groupEnrollmentExists)
{
    Write-Host "`nAdding group enrollment $groupEnrollmentId"
    az iot dps enrollment-group create -g $ResourceGroup --dps-name $dpsName --enrollment-id $groupEnrollmentId --output none
}

$dpsGroupEnrollmentPrimaryKey = az iot dps enrollment-group show -g $ResourceGroup --dps-name $dpsName --enrollment-id $groupEnrollmentId --show-keys --query 'attestation.symmetricKey.primaryKey' --output tsv

# Writing group enrollment primary key to KV
Write-Host("`nWriting secrets to KeyVault $keyVaultName")
$userObjectId = az ad signed-in-user show --query objectId --output tsv
az keyvault set-policy -g $ResourceGroup --name $keyVaultName --object-id $userObjectId --secret-permissions delete get list set --output none
az keyvault secret set --vault-name $keyVaultName --name "DpsGroupEnrollmentPrimaryKey" --value $dpsGroupEnrollmentPrimaryKey --output none

# Add persmissions to TSI