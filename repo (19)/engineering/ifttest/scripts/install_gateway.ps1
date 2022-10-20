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
# Hardcode for now while we work out the best method of storing this
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
