##
## Get ISA Settings from Azure Keyvault and bulid the Web.config file from the template
## The VMs Managed Identity must have 'Get' access to the Key Vaults Secrets
#
# The following secrets must exist in the ISA application keyvault for the automated builds to work
#
# CIFConnectionString - Connection String to SQL AG specific to CIF server
# CIFCIConnectionString - Connection String to SQL AG specific to CIF Client Import Interface
# ISA-Web-Site - We need the Root & Sub CA certs from this chain, not the cert itself.

# Get token from Azure keyvault authentication endpoint
#
$Response = Invoke-RestMethod -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -Method GET -Headers @{Metadata="true"}

# Split out the actual token from the response
#
$KeyVaultToken = $Response.access_token

# Present the token and get the secrets we want
#
# point to the correct keyvault and web load balanacer for the environment
switch ( $env:computername )
{
    'devappsisac1'      { $keyvault = 'dev-apps-isa-kv';    $endpoint = 'devappsisalb.mgt.prvdns.vaultexuk.net'      }
    'devappsisad2c1'    { $keyvault = 'dev-apps-isad2-kv';  $endpoint = 'devappsisad2lb.mgt.prvdns.vaultexuk.net'    }
    'tstappsisac1'      { $keyvault = 'tst-apps-isa-kv';    $endpoint = 'tstappsisalb.mgt.prvdns.vaultexuk.net'      }
    'sitappsisac1'      { $keyvault = 'sit-apps-isa-kv';    $endpoint = 'sitappsisalb.mgt.prvdns.vaultexuk.net'      }
}
$CIFConnectionString = Invoke-RestMethod -Uri https://$keyvault.vault.azure.net/secrets/CIFConnectionString?api-version=2016-10-01 -Method GET -Headers @{Authorization="Bearer $KeyVaultToken"}
$CIFCIConnectionString = Invoke-RestMethod -Uri https://$keyvault.vault.azure.net/secrets/CIFCIConnectionString?api-version=2016-10-01 -Method GET -Headers @{Authorization="Bearer $KeyVaultToken"}

# Replace the standard details in the Config files for the CIF Services with the connection string from the Keyvault
#
# Core Service
$config_file = "D:\Program Files\CPS\CIF Core Service\DLR.CifCoreDbAccess.dll.config"
(Get-Content $config_file) | Foreach-Object {
    $_ -replace "Persist Security Info=False;User ID=cifowner;Password=cvhUTUDU8sd9YREqb/2kaQ==;Database=ISADB;Server=\(local\)", $CIFConnectionString.value `
} | Set-Content $config_file

# Scheduler Service
$config_file = "D:\Program Files\CPS\CIF Scheduler Service\DLR.CifCoreDbAccess.dll.config"
(Get-Content $config_file) | Foreach-Object {
    $_ -replace "Persist Security Info=False;User ID=cifowner;Password=cvhUTUDU8sd9YREqb/2kaQ==;Database=ISADB;Server=\(local\)", $CIFConnectionString.value `
} | Set-Content $config_file

# Task Engine
$config_file = "D:\Program Files\CPS\CIF TaskStatus Service\DLR.CifCoreDbAccess.dll.config"
(Get-Content $config_file) | Foreach-Object {
    $_ -replace "Persist Security Info=False;User ID=cifowner;Password=cvhUTUDU8sd9YREqb/2kaQ==;Database=ISADB;Server=\(local\)", $CIFConnectionString.value `
} | Set-Content $config_file

# Client Import Interface
$config_file = "D:\Program Files\CPS\CPS Client Import Service\CPS.ClientImport.dll.config"
(Get-Content $config_file) | Foreach-Object {
    $_ -replace ([regex]::Escape('Persist Security Info=False;User ID=ISAUser;Password=n2r2SNPD0M3dbRUp+qasRA==;Database=ISADB;Server=(local)')), $CIFCIConnectionString.value `
} | Set-Content $config_file


# Get the Certificate for the ISA Website and write it to a file in the Media folder
# We need the root & sub CA certificates to be installed so that the CIF Client Import Interface SSL will trust the ISA Web Cert
#
(Invoke-RestMethod -Uri https://$keyvault.vault.azure.net/secrets/ISA-Web-Site?api-version=2016-10-01 -Method GET -Headers @{Authorization="Bearer $KeyVaultToken"}).value | out-file c:\media\ISAcert.pfx

# Update the server name of the Web Service Server in the CPS.WinService.exe.config file and update the bindings
#

$config_file = "D:\Program Files\CPS\CPS Client Import Service\CPS.WinService.exe.config"
(Get-Content $config_file) | Foreach-Object {
    $_ -replace ([regex]::Escape('endpoint address="http://localhost/Services/Client"')), "endpoint address=`"https://$endpoint/Services/Client`"" `
    -replace ([regex]::Escape('endpoint address="http://localhost/Services/xtclientwebservice"')), "endpoint address=`"https://$endpoint/Services/xtclientwebservice`"" `
    -replace ([regex]::Escape('<binding name="BasicHttpBinding_IClientService" />')), "<binding name=`"BasicHttpBinding_IClientService`">`r`n`t`t<security mode=`"Transport`">`r`n`t`t`t<transport clientCredentialType=`"None`" />`r`n`t`t</security>`r`n`t </binding> " `
    -replace ([regex]::Escape('<binding name="BasicHttpBinding_IClientService1" />')), "<binding name=`"BasicHttpBinding_IClientService1`">`r`n`t`t<security mode=`"Transport`">`r`n`t`t`t<transport clientCredentialType=`"None`" />`r`n`t`t</security>`r`n`t</binding> " `
} | Set-Content $config_file



