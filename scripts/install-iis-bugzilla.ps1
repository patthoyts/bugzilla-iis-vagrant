$SiteName = 'Bugzilla'
$PoolName = "PERL"
$SiteUser = "IIS APPPOOL\$PoolName"
$SiteDir = "C:\$SiteName"
$PerlExe = (Get-Command perl).Definition
$GitExe = (Get-Command git).Definition
$BugzillaRepo = 'http://git.mozilla.org/bugzilla/bugzilla'
$BugzillaBranch = 'master' #'release-4.4-stable'

function Extract-Zip ($file, $destination) {
    Write-Output "Unpacking extension to $destination"
    $shell = New-Object -com Shell.Application
    $zip = $shell.NameSpace($file)
    if (!(Test-Path $destination)) { New-Item -Path $destination -ItemType Directory | Out-Null }
    $zip.Items() | %{ $shell.Namespace($destination).CopyHere($_) }
}

# Check out git and apply any local patches and extensions.
if (!(Test-Path $SiteDir)) {
    $SiteRoot = Split-Path $SiteDir -Parent
    $cmd = "clone --branch ""$BugzillaBranch"" ""$BugzillaRepo"" ""$SiteDir"""
    Start-Process -FilePath $GitExe -WorkingDirectory $SiteRoot -ArgumentList $cmd -Wait -NoNewWindow
    $cmd = "config --global user.name ""Vagrant User"""
    Start-Process -FilePath $GitExe -WorkingDirectory $SiteRoot -ArgumentList $cmd -Wait -NoNewWindow
    $cmd = "config --global user.email vagrant@example.com"
    Start-Process -FilePath $GitExe -WorkingDirectory $SiteRoot -ArgumentList $cmd -Wait -NoNewWindow
    if (Test-Path "C:\Vagrant\patches") {
        Get-ChildItem "C:\Vagrant\patches" | %{
            $cmd = "am ""$($_.FullName)"""
            Start-Process -FilePath $GitExe -WorkingDirectory $SiteDir `
                -ArgumentList $cmd -Wait -NoNewWindow
        }
    }
    if (Test-Path "C:\Vagrant\extensions") {
        Push-Location $SiteDir
        Get-ChildItem "C:\Vagrant\extensions" `
            | %{ Extract-Zip $_.FullName "$SiteDir\extensions" }
        Pop-Location
    }
}

# Enable IIS powershell support
Add-PSSnapin WebAdministration -ErrorAction SilentlyContinue
Import-Module WebAdministration -ErrorAction SilentlyContinue

# Create an application pool for the perl applications
if (!(Test-Path IIS:\AppPools\$PoolName)) {
    Write-Output "Creating application pool $PoolName..."
    New-WebAppPool $PoolName
    Set-ItemProperty IIS:\AppPools\$PoolName managedRuntimeVersion ""
    Set-ItemProperty IIS:\AppPools\$PoolName startMode "AlwaysRunning"
}

# Create the application under the default site (or create a new site on a new port)
if (!(Test-Path "IIS:\Sites\Default Web Site\$SiteName")) {
    Write-Output "Creating $SiteName web application..."
   @'
<configuration>
    <system.webServer>
        <defaultDocument>
            <files>
                <add value="index.cgi" />
            </files>
        </defaultDocument>
        <staticContent>
            <clientCache cacheControlMode="UseMaxAge" cacheControlMaxAge="10.00:00:00" />
        </staticContent>
        <httpProtocol allowKeepAlive="true" />
    </system.webServer>
</configuration>
'@ | Out-File "$SiteDir\web.config"
   #New-Website $SiteName -Port 8080 -PhysicalPath $SiteDir -ApplicationPool $PoolName
   New-WebApplication -Name $SiteName -Site "Default Web Site" -PhysicalPath "$SiteDir" -ApplicationPool $PoolName
   New-WebHandler -name "PerlCGI" -path '*.cgi' -verb 'GET,POST,HEAD' `
       -modules 'CgiModule' -location "Default Web Site/$SiteName" `
       -ScriptProcessor "$PerlExe -x""$SiteDir"" -wT ""%s"" %s"
   Add-WebConfiguration //security/isapiCgiRestriction -value @{
       description = "PerlCGI"
       path = "$PerlExe -x""$SiteDir"" -wT ""%s"" %s"
       allowed = 'True'
   }
   #Add-WebConfiguration //defaultDocument/files "IIS:\Sites\Default Web Site\$SiteName" `
   #    -atIndex 0 -Value @{value = "index.cgi"}
}

# Run Bugzilla's checksetup script to configure the application
# Subsitute the urlbase and cookie param values to match this installation.
$am = "`$answer{'urlbase'} = '';"
$ar = "`$answer{'urlbase'} = 'http://localhost/$($SiteName)/';"
$bm = "`$answer{'cookiepath'} = '/';"
$br = "`$answer{'cookiepath'} = '/$($SiteName)/';"
Get-Content "C:\tmp\initial.responses" `
    | %{ $_.Replace($am,$ar).Replace($bm,$br) } > "C:\tmp\bugzilla.responses"
Start-Process -FilePath $PerlExe -WorkingDirectory $SiteDir -Wait -NoNewWindow `
    -ArgumentList '-w checksetup.pl "c:\tmp\bugzilla.responses" --verbose'

function update-acl ($path, $account, $access)
{
  $acl = Get-Acl $path
  $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($account, $access, "ContainerInherit, ObjectInherit", "InheritOnly", "Allow")
  $acl.SetAccessRule($rule)
  Set-Acl $path $acl
}

# set the site directory tree to be readable by the Application Pool user id
#add-ntfsaccess -path "$SiteDir" -account $SiteUser -access Read
Write-Output "Updating file system permissions for $SiteDir..."
update-acl "$SiteDir" "IUSR" "ReadAndExecute"
update-acl "$SiteDir" $SiteUser "ReadAndExecute"

# Set the data and graph subdirectories to be writable.
if (!(Test-Path "$SiteDir\data")) {
   New-Item -Path "$SiteDir\data" -ItemType Directory
   New-Item -Path "$SiteDir\graphs" -ItemType Directory
}
update-acl "$SiteDir\data" $SiteUser "FullControl"
update-acl "$SiteDir\data" "IUSR" "FullControl"
update-acl "$SiteDir\graphs" $SiteUser "FullControl"
update-acl "$SiteDir\graphs" "IUSR" "FullControl"
