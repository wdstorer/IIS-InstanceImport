########################################################
#IIS-InstanceImport.ps1
#Created by: Will Storer
#Last-Modified: 5/2/2015
#
#THIS SCRIPT IMPORTS IIS INSTANCE INFORMATION INTO
#THE SQL DATABASE
#
########################################################
param(
  [string]$siteName = ""
)

#CONFIGURATION PARAMS
$dbHost = "172.18.73.12"
$dbDB = "NJOps"

#FUNCTIONS
function installWebAdminModule()
{
    Write-Host "Checking Installed IIS version:"
    $iisVersion = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\InetStp";
    Write-host IIS major version : $iisVersion.MajorVersion
    Write-host IIS minor version : $iisVersion.MinorVersion

    if (($iisVersion.MajorVersion -eq 7 ) -and ($iisVersion.MinorVersion -gt 0 ))
    {
        Write-host Detected IIS Major Version : $iisVersion.MajorVersion and Minor version : $iisVersion.MinorVersion. Hence importing WebAdministration module via Import-Module.
        If ( ! (Get-module WebAdministration )) 
        {
            Import-Module WebAdministration
        }
    }
    else
    {
        Write-host Detected IIS Major Version : $iisVersion.MajorVersion and Minor version : $iisVersion.MinorVersion. Hence importing WebAdministration via Add-PSSnapin.
        if ( (Get-PSSnapin -Name WebAdministration -ErrorAction SilentlyContinue) -eq $null )
        {
            Add-PSSnapin WebAdministration
        }
    }
}

#MAIN
installWebAdminModule

Set-Location IIS:\Sites

Try
{
$connection=new-object System.Data.SqlClient.SQLConnection 
$connection.ConnectionString = "Server=$($dbHost);Database=$($dbDB);Integrated Security=True;Connect Timeout=0"
$connection.Open()
$command = New-Object System.Data.SQLClient.SQLCommand
$command.connection = $connection
}
Catch
{
    Write-host "Sorry, could not connect to the database"
    Write-host $error[0].Exception.Message
    exit
}

$serverName = [System.Net.Dns]::GetHostName() 

if ($siteName -ne "")
{
    $itemParam = get-item $siteName | select Name, PhysicalPath, Bindings
    $bind = $itemParam | select -expa bindings | select -expa collection | select -expa bindinginformation 
    write-output $itemParam."Name"
    write-output $itemParam."Physical Path"
    write-output $bind
    write-output $itemParam
}
else
{
    $items = get-childitem | select Name, ID, State, PhysicalPath, Bindings 

    foreach ($item in $items) 
    { 
        $bind = ($item | select -expa bindings | select -expa collection | select -expa bindinginformation ) -join "|"
        $apppools = (Get-WebApplication -Site $item.Name | select -expa applicationPool -unique) -join "|"
        #write-output $bind
        #write-output $item
        $sql = "exec [dbo].[njo_sp_UpdateSite] '$($serverName)','$($item.Name)','$($item.PhysicalPath)','$($bind)','$($apppools)','','$($item.ID)','$($item.State)'"
        $command.commandtext = $sql
        $result = $command.ExecuteNonQuery()
        #write-output $apppools
        #write-output $sql
    } 
}

write-output "done"

exit