##
## Get ISA ATM Settings from Azure Keyvault 
## The VMs Managed Identity must have 'Get' access to the Key Vaults Secrets
#
# The following secrets must exist in the ISA application keyvault for the automated builds to work
#
# ATMConnectionString - Connection String to SQL AG specific to ATM Split Bag config

# Get token from Azure keyvault authentication endpoint
#
$Response = Invoke-RestMethod -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -Method GET -Headers @{Metadata="true"}

# Split out the actual token from the response
#
$KeyVaultToken = $Response.access_token

# Present the token and get the secrets we want
#
# point to the correct keyvault for the environment
switch -wildcard ( $env:computername ) 
{
    'devappsisaw*' { $keyvault = 'dev-apps-isa-kv'    }
    'devappsisad2w*' { $keyvault = 'dev-apps-isad2-kv'    }
    'tstappsisaw*' { $keyvault = 'tst-apps-isa-kv'    }
    'sitappsisaw*' { $keyvault = 'sit-apps-isa-kv'    }
}
$CIFConnectionString = Invoke-RestMethod -Uri https://$keyvault.vault.azure.net/secrets/ATMConnectionString?api-version=2016-10-01 -Method GET -Headers @{Authorization="Bearer $KeyVaultToken"}

# Replace the text in the config file with the secret from the Key Vault
#

$config_file = "D:\inetpub\wwwroot\ISA\bin\Plugins\Cps.Isa.AtmBagSplitAlgorithm.Utilities.dll.config"
(Get-Content $config_file) | Foreach-Object {
    $_ -replace "Server=10.0.0.152;Database=ISADB;User Id=IsaUser;Password=q6ZpKBYSr3scYDVufRzKcA==;Max Pool Size=1000;Connection Timeout=30;", $CIFConnectionString.value `
} | Set-Content $config_file





