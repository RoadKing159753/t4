#
#  Install the Datagateway and any Pre-reqs
#

#  Install Powershell 7 if required.  The datagateway module requires PS7
#
$Psversion = (Get-Host).Version
if($Psversion.Major -ge 7)
{
if (!(Get-Module "DataGateway")) {
Install-Module -Name DataGateway -force
}
if (!(Get-Module "AZ")) {
Install-Module -Name AZ -Repository PSGallery -Force 
}
#
# Managed Identity Password is stored in the /etc/ansible/secure folder.  This is owned by Ansadmin and set to 700. 
#
#$securePassword = `cat /etc/ansible/secure/DgwId` | ConvertTo-SecureString -AsPlainText -Force;
#
# Hardcode for now while we work out the best method of storing this
$securePassword = "A_h7Q~tXQrIFzrKWmdprTFTSAoJ3jCsKf5Cr7" | ConvertTo-SecureString -AsPlainText -Force;
# These need to be pulled from Azure too rather than being hardcoded
$ApplicationId ="59d55603-5939-4884-9027-5d24d11c4d50";
$Tenant = "9f2ead76-dd88-448e-be8e-1f4e81818fc0";
$GatewayName = "VXDataGateway2";
$RecoverKey = "VXRecovery!" | ConvertTo-SecureString -AsPlainText -Force;
$userIDToAddasAdmin = "dbf846ab-58ff-4533-bd0c-1bc6f22264d6"
#
# Connect to the tenant with the managed identity.  Need to work on this to use different creds per environment
#
Connect-DataGatewayServiceAccount -ApplicationId $ApplicationId -ClientSecret $securePassword  -Tenant $Tenant
#
#  install the datagateway onto the VM and add the cluster into PowerBi
#
Install-DataGateway -AcceptConditions 
$GatewayDetails = Add-DataGatewayCluster -Name $GatewayName -RecoveryKey  $RecoverKey -OverwriteExistingGateway
Add-DataGatewayClusterUser -GatewayClusterId $GatewayDetails.GatewayObjectId -PrincipalObjectId $userIDToAddasAdmin -AllowedDataSourceTypes $null -Role Admin
}
else{
exit 1
}
