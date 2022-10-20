if ((Invoke-Sqlcmd -Query "-- check location of master database
use master
go
select count(physical_name)  from sys.database_files
where physical_name like 'c:\%'
" -ServerInstance $env:computername).column1 -ge 1)
{

  $masterDataOld = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\master.mdf'
  $masterDataNew = 'F:\data\master.mdf'

  $masterLogOld = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\mastlog.ldf'
  $masterLogNew = 'G:\log\mastlog.ldf'

  #Get SQL Server Instance Path:
  $SQLService = "SQL Server (MSSQLSERVER)";
  $SQLInstancePath = "";
  $SQLServiceName = ((Get-Service | WHERE { $_.DisplayName -eq $SQLService }).Name).Trim();
  If ($SQLServiceName.contains("`$")) { $SQLServiceName = $SQLServiceName.SubString($SQLServiceName.IndexOf("`$")+1,$SQLServiceName.Length-$SQLServiceName.IndexOf("`$")-1) }
  foreach ($i in (get-itemproperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server").InstalledInstances)
  {
     If ( ((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL").$i).contains($SQLServiceName) )
    { $SQLInstancePath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\"+`
    (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL").$i}
  }
  $SQLInstancePath

  # Read Existing SQL Server Startup Parameter
  (Get-ItemProperty "$SQLInstancePath\MSSQLServer\Parameters" | Select SQLArg*  | Format-List | Out-String ).trim() -replace "SQLArg","`tSQLArg"

  #Update SQL Server Startup Parameter
  $ParamNumber = "0"
  $ParamValue = "-d$masterDataNew"
  Set-ItemProperty -Path "$SQLInstancePath\MSSQLServer\Parameters" -Name ("SQLArg$ParamNumber") -Value $ParamValue
  (Get-ItemProperty "$SQLInstancePath\MSSQLServer\Parameters" | Select SQLArg*  | Format-List | Out-String ).trim() -replace "SQLArg","`tSQLArg"

  #Update SQL Server Startup Parameter
  $ParamNumber = "2"
  $ParamValue = "-l$masterLogNew"
  Set-ItemProperty -Path "$SQLInstancePath\MSSQLServer\Parameters" -Name ("SQLArg$ParamNumber") -Value $ParamValue
  (Get-ItemProperty "$SQLInstancePath\MSSQLServer\Parameters" | Select SQLArg*  | Format-List | Out-String ).trim() -replace "SQLArg","`tSQLArg"

  Stop-Service -Name "mssqlserver" -Force

  Move-Item -Path $masterDataOld -Destination $masterDataNew
  Move-Item -Path $masterLogOld -Destination $masterLogNew

  write-output "changed"
}