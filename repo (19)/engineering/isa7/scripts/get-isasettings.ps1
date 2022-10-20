##
## Get ISA Settings from Azure Keyvault and bulid the Web.config file from the template
## The VMs Managed Identity must have 'Get' access to the Key Vaults Secrets
#
# The following secrets must exist in the ISA application keyvault for the automated builds to work
#
# SqlConnectString - Connection String to SQ AG
# MongoDbConnectionString - Session Server MongoDB Connection String
# ActivationCode - License code for the ISA application
# ValidationKey & DecryptionKey - IIS Machine Keys
# ISA-Web-Site - SSL Certificate for the ISA Website

# Get token from Azure keyvault authentication endpoint
#
$Response = Invoke-RestMethod -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -Method GET -Headers @{Metadata="true"}

# Split out the actual token from the response
#
$KeyVaultToken = $Response.access_token
# point to the correct keyvault for the environment
switch -wildcard ( $env:computername ) 
{
    'devappsisaw*' { $keyvault = 'dev-apps-isa-kv'    }
    'devappsisad2w*' { $keyvault = 'dev-apps-isad2-kv'    }
    'tstappsisaw*' { $keyvault = 'tst-apps-isa-kv'    }
    'sitappsisaw*' { $keyvault = 'sit-apps-isa-kv'    }
}
# Present the token and get the secrets we want
#
$SqlConnectionString = Invoke-RestMethod -Uri https://$keyvault.vault.azure.net/secrets/SqlConnectionString?api-version=2016-10-01 -Method GET -Headers @{Authorization="Bearer $KeyVaultToken"}
$MongoDbConnectionString = Invoke-RestMethod -Uri https://$keyvault.vault.azure.net/secrets/MongoDbConnectionString?api-version=2016-10-01 -Method GET -Headers @{Authorization="Bearer $KeyVaultToken"}
$ActivationCode = Invoke-RestMethod -Uri https://$keyvault.vault.azure.net/secrets/ActivationCode?api-version=2016-10-01 -Method GET -Headers @{Authorization="Bearer $KeyVaultToken"}
$ValidationKey = Invoke-RestMethod -Uri https://$keyvault.vault.azure.net/secrets/ValidationKey?api-version=2016-10-01 -Method GET -Headers @{Authorization="Bearer $KeyVaultToken"}
$DecryptionKey = Invoke-RestMethod -Uri https://$keyvault.vault.azure.net/secrets/DecryptionKey?api-version=2016-10-01 -Method GET -Headers @{Authorization="Bearer $KeyVaultToken"}

# Get the Certificate for the ISA Website and write it to a file in the Media folder
#
(Invoke-RestMethod -Uri https://$keyvault.vault.azure.net/secrets/ISA-Web-Site?api-version=2016-10-01 -Method GET -Headers @{Authorization="Bearer $KeyVaultToken"}).value | out-file c:\media\ISAcert.pfx

# Replace the text in the Web.config template with the secrets from the Key Vault and write the new Web.config
#
$template_file = 'c:\media\Web.config'
$destination_file =  'd:\inetpub\wwwroot\isa\Web.config'
(Get-Content $template_file) | Foreach-Object {
    $_ -replace 'VaultexSqlConnectionString', $SqlConnectionString.value `
    -replace 'VaultexMongoDbConnectionString', $MongoDbConnectionString.value `
    -replace 'VaultexActivationCode', $ActivationCode.value `
    -replace 'VaultexValidationKey', $ValidationKey.value `
    -replace 'VaultexDecryptionKey', $DecryptionKey.value `
} | Set-Content $destination_file
