@echo off
IF "%1" == "" goto err
setlocal
set MOVETO=%1:\
REM simple error handling if drive does not exist or argument is wrong
IF NOT EXIST %MOVETO% goto err
REM Backup IIS config before we start changing config to point to the new path
%windir%\system32\inetsrv\appcmd add backup beforeRootMove

REM Stop all IIS services
iisreset /stop
REM Copy all content
REM /O - copy ACLs
REM /E - copy sub directories including empty ones
REM /I - assume destination is a directory
REM /Q - quiet
REM echo on, because user will be prompted if content already exists.
echo on
xcopy %systemdrive%\inetpub %MOVETO%inetpub /O /E /I /Q
@echo off
REM Move AppPool isolation directory
reg add HKLM\System\CurrentControlSet\Services\WAS\Parameters /v ConfigIsolationPath /t REG_SZ /d %MOVETO%inetpub\temp\appPools /f
REM Move logfile directories
%windir%\system32\inetsrv\appcmd set config -section:system.applicationHost/sites -siteDefaults.traceFailedRequestsLogging.directory:"%MOVETO%inetpub\logs\FailedReqLogFiles"
%windir%\system32\inetsrv\appcmd set config -section:system.applicationHost/sites -siteDefaults.logfile.directory:"%MOVETO%inetpub\logs\logfiles"
%windir%\system32\inetsrv\appcmd set config -section:system.applicationHost/log -centralBinaryLogFile.directory:"%MOVETO%inetpub\logs\logfiles"
%windir%\system32\inetsrv\appcmd set config -section:system.applicationHost/log -centralW3CLogFile.directory:"%MOVETO%inetpub\logs\logfiles"
%windir%\system32\inetsrv\appcmd set config -section:system.applicationHost/sites -siteDefaults.ftpServer.logFile.directory:"%MOVETO%inetpub\logs\logfiles"
%windir%\system32\inetsrv\appcmd set config -section:system.ftpServer/log -centralLogFile.directory:"%MOVETO%inetpub\logs\logfiles"
REM Move config history location, temporary files, the path for the Default Web Site and the custom error locations
%windir%\system32\inetsrv\appcmd set config -section:system.applicationhost/configHistory -path:%MOVETO%inetpub\history
%windir%\system32\inetsrv\appcmd set config -section:system.webServer/asp -cache.disktemplateCacheDirectory:"%MOVETO%inetpub\temp\ASP Compiled Templates"
%windir%\system32\inetsrv\appcmd set config -section:system.webServer/httpCompression -directory:"%MOVETO%inetpub\temp\IIS Temporary Compressed Files"
%windir%\system32\inetsrv\appcmd set vdir "Default Web Site/" -physicalPath:%MOVETO%inetpub\wwwroot
%windir%\system32\inetsrv\appcmd set config -section:httpErrors /[statusCode='401'].prefixLanguageFilePath:%MOVETO%inetpub\custerr
%windir%\system32\inetsrv\appcmd set config -section:httpErrors /[statusCode='403'].prefixLanguageFilePath:%MOVETO%inetpub\custerr
%windir%\system32\inetsrv\appcmd set config -section:httpErrors /[statusCode='404'].prefixLanguageFilePath:%MOVETO%inetpub\custerr
%windir%\system32\inetsrv\appcmd set config -section:httpErrors /[statusCode='405'].prefixLanguageFilePath:%MOVETO%inetpub\custerr
%windir%\system32\inetsrv\appcmd set config -section:httpErrors /[statusCode='406'].prefixLanguageFilePath:%MOVETO%inetpub\custerr
%windir%\system32\inetsrv\appcmd set config -section:httpErrors /[statusCode='412'].prefixLanguageFilePath:%MOVETO%inetpub\custerr
%windir%\system32\inetsrv\appcmd set config -section:httpErrors /[statusCode='500'].prefixLanguageFilePath:%MOVETO%inetpub\custerr
%windir%\system32\inetsrv\appcmd set config -section:httpErrors /[statusCode='501'].prefixLanguageFilePath:%MOVETO%inetpub\custerr
%windir%\system32\inetsrv\appcmd set config -section:httpErrors /[statusCode='502'].prefixLanguageFilePath:%MOVETO%inetpub\custerr
REM Make sure Service Pack and Hotfix Installers know where the IIS root directories are
reg add HKLM\Software\Microsoft\inetstp /v PathWWWRoot /t REG_SZ /d %MOVETO%inetpub\wwwroot /f
reg add HKLM\Software\Microsoft\inetstp /v PathFTPRoot /t REG_SZ /d %MOVETO%inetpub\ftproot /f
REM Do the same for x64 directories
if not "%ProgramFiles(x86)%" == "" reg add HKLM\Software\Wow6432Node\Microsoft\inetstp /v PathWWWRoot /t REG_EXPAND_SZ /d %MOVETO%inetpub\wwwroot /f
if not "%ProgramFiles(x86)%" == "" reg add HKLM\Software\Wow6432Node\Microsoft\inetstp /v PathFTPRoot /t REG_EXPAND_SZ /d %MOVETO%inetpub\ftproot /f
REM Restart all IIS services
iisreset /start
:err