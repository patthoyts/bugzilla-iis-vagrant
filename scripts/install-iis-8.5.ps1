# Install IIS 8.5 component on Windows Server 2012r2
#
# Add IncludeManagementTools to the command to get the management tooling.

$feature = Get-WindowsFeature Web-Server
if (!$feature.Installed) {
  Import-Module ServerManager
  Write-Output "Installing Web-Server feature..."
  #Add-WindowsFeature Web-Server -IncludeAllSubFeature -IncludeManagementTools
  Add-WindowsFeature Web-Server, Web-WebServer, Web-Security, Web-Filtering, Web-CGI
}
