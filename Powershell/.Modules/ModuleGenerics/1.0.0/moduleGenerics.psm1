## You must place the module in one of the appropriate locations before running the scripts
##      - C:\Users\<USERS>\Documents\WindowsPowerShell\Modules
##      - C:\Program Files\WindowsPowerShell\Modules
##      - C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules


#New-Item -Path "E:\Script Nas" -ItemType SymbolicLink -Target "\\nas.webi-time.fr\Nas\Perso\3 - Script & Programmation\0 - Exakis-Nelite\"
#New-Item -Path "C:\Users\daubril\Documents\WindowsPowerShell\Modules\ModuleGenerics" -ItemType SymbolicLink -Target 'E:\Script Nas\Scripts\.Modules\ModuleGenerics\'
#New-Item -Path "C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules\ModuleGenerics" -ItemType SymbolicLink -Target 'E:\Script Nas\Scripts\.Modules\ModuleGenerics\'


$ErrorActionPreference = 'Stop'

#############################################################################
############################### LOGS FUNCTION ###############################
#############################################################################

#region LOGS FUNCTION
<# Log
.SYNOPSIS
    Write log messages to log files and/or the PowerShell console.

.DESCRIPTION
    The Log function is used to write log messages to log files and/or display them in the PowerShell console. 
    It supports custom log folders, log file names, log levels, and log colors. You can specify whether to write logs to files, 
    whether to include timestamps, and whether to include line breaks.

.PARAMETER Contexts
    Specifies an array of context folders where log files will be written.

.PARAMETER sInput
    Specifies an array of log messages to be written.

.PARAMETER lvl
    Specifies the log level. Log messages will be displayed in the console if the VerboseLvl is greater than or equal to this level.
    The `$lvl` parameter determines the verbosity level of the logging in the script. It allows you to control the amount of detail 
    included in the log output. You can set the verbosity level to control which log messages are displayed in the console 
    and written to log files. There are six predefined levels:

    - `0`: Minimal logging. Only critical errors are displayed.
    - `1`: Basic logging. Displays basic information and errors.
    - `2`: Standard logging. Displays standard log messages, basic information, and errors.
    - `3`: Verbose logging. Displays detailed log messages, standard information, and errors.
    - `4`: Debug logging. Displays debug information, detailed log messages, standard information, and errors.
    - `5`: Diagnostic logging. Displays diagnostic information, debug information, detailed log messages, standard information, and errors.

    By specifying a verbosity level, you can filter the log output to focus on the information that is most relevant to your needs.


.PARAMETER color
    Specifies the color for log messages in the console.

.PARAMETER LogPath
    Specifies the root path where log folders will be created.

.PARAMETER CustomName
    Specifies a custom name to be appended to the log file name.

.PARAMETER NoOutPut
    Suppresses writing log messages to log files.

.PARAMETER NoNewLine
    Suppresses the addition of line breaks to log messages.

.PARAMETER NoDate
    Suppresses the addition of timestamps to log messages.

.NOTES
    This function allows for flexible logging configuration and can be used to create log files for various purposes.

.EXAMPLE
    Log -Contexts "Script" -sInput "This is a log message." -lvl 1 -color "Cyan"
    This example writes a log message to a log file in the "Script" context folder and displays it in the console with the specified color.

#>
Function Log {
    Param (
        [Parameter(Mandatory=$true, Position=0)][string[]]$Contexts,
        [Parameter(Mandatory=$true, Position=1)][string[]]$sInput, 
        [Parameter(Mandatory=$false, Position=2)][int]$lvl = 0,
        [Parameter(Mandatory=$false, Position=3)][string]$color = "Cyan",
        [Parameter(Mandatory=$false, Position=4)][string]$LogPath = $global:Path_Logs,
        [Parameter(Mandatory=$false, Position=5)][string]$CustomName ="",
        [Parameter(Mandatory=$false, Position=6)][switch]$NoOutPut,
        [Parameter(Mandatory=$false, Position=7)][switch]$NoNewLine,
        [Parameter(Mandatory=$false, Position=8)][switch]$NoDate,
        [Parameter(Mandatory=$false, Position=9)][string]$CustomBeginText =""
    )
    # Retrieve the full path of all folders (contexts) to write logs
        $logFolders = $Contexts | ForEach-Object { Join-Path $LogPath $_ }
    
    # Retrieve the full paths of the log files to write
        $sLogFile = Join-Path $logFolders ("Log_" + $global:Date_Logs_File + $CustomName +".log")
    
    # Format each line to be written in the logs
        $sLineTimeStamp = Get-Date -f "dd/MM/yyyy HH:mm:ss"
        $sLine = $sInput | ForEach-Object { $sLineTimeStamp + " - " + $CustomBeginText + $_ }

     # If -NoOutput is specified, the function does not write a log file
    if (-not $NoOutPut) 
    { 
        # Test the folders and create them if necessary
        Test-Folder $logFolders

        # For each log file to write to,
        $sLogFile | ForEach-Object { 
           
            if ($noNewLine) 
            {                     
                $sLine | Out-File $_ -Append -Force -NoNewline
            }
            elseif ($noDate) 
            {
                $sInput -join "`r`n" | Out-File $_ -Append -Force
            }
            else
            {
                $sLine -join "`r`n" | Out-File $_ -Append -Force
            }
        }
    }
    # Display in the PowerShell console if the VerboseLvl is greater than or equal to the defined level
    if ($lvl -le $VerboseLvl) { 
        if ($noNewLine) 
        { 
            Write-Host ($sLine) -ForegroundColor $color -NoNewline
        }
        elseif ($noDate) 
        {
            Write-Host ($sInput -join "`r`n") -ForegroundColor $color
        }
        else
        {
            Write-Host ($sLine -join "`r`n") -ForegroundColor $color
        }
    }
}

<# Get-DebugError 
.SYNOPSIS
    Handle and log detailed error information for debugging purposes.

.DESCRIPTION
    The `Get-DebugError` function is designed to handle and log detailed error information for debugging purposes. It captures 
    information about an error, including the error message, line number, stack trace, and exception type, and logs it with a 
    distinctive marker for easy identification.

.PARAMETER e
    Specifies the error object to be processed and logged.

.PARAMETER num
    Specifies an optional numerical identifier for the error message. It can help categorize and distinguish different types of 
    errors. The default value is `1`.

.NOTES
    The `Get-DebugError` function is a useful tool for troubleshooting and debugging scripts. It logs detailed error information 
    that can assist in identifying the cause of issues and streamlining the debugging process.

.EXAMPLE
    Get-DebugError -e $ErrorObject -num 2
    This example calls the `Get-DebugError` function to process and log an error specified by the `$ErrorObject` variable. 
    The `-num` parameter is set to `2` to categorize the error. Detailed error information, including the error message, line number, 
    stack trace, and exception type, will be logged for debugging purposes.

#>
Function Get-DebugError {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]$e,
        [Parameter(Mandatory=$false, Position=1)]$num = 1,
        [Parameter(Mandatory=$false, Position=2)]$custom = ""
    )
    try {
        Log "Error" "ERROR FOUND ################################################################################################################" 99
        Log "Error" "Error - Line  [$($e.InvocationInfo.ScriptLineNumber)] - `$_ = $($e)" $num Red -CustomBeginText $custom
        Log "Error" "Error - Line  [$($e.InvocationInfo.ScriptLineNumber)] - StackTrace = $($e.ScriptStackTrace)" 99 Red
        Log "Error" "Error - Line  [$($e.InvocationInfo.ScriptLineNumber)] - ExceptionType = $($e.Exception.GetType().FullName)" 99 Red
        Log "Error" $(($e | Select-Object * | Format-List | Out-String)) 99 Red
        #Log "Error" $(($e.Exception | Select-Object * | Format-List | Out-String)) 99 Red
    }
    catch {
        write-host $_
    }
   
}
#endregion LOGS FUNCTION

#############################################################################
############################# TESTING FUNCTION ##############################
#############################################################################

#region TESTING FUNCTION

<# Test-Folder 
.SYNOPSIS
    Check for the existence of specified folders and create them if they don't exist.

.DESCRIPTION
    This PowerShell function, Test-Folder, is designed to verify the existence of specified folders and create them if they are not found. 
    It is typically used to ensure that the required directory structure exists before performing operations that depend on these folders.

.PARAMETER Path
    Specifies an array of folder paths to check and create if they don't exist.

.NOTES
    If the folder specified in the 'Path' parameter does not exist, this function attempts to create it. Any errors encountered during
    folder creation are logged, including the error message and stack trace.

.EXAMPLE
    Test-Folder -Path "C:\Logs", "D:\Results"
    This example checks for the existence of the "C:\Logs" and "D:\Results" folders. If any of these folders are not found, they will be 
    created.

#>
function Test-Folder {
    param (
        [string[]]$Path  # An array of folder paths to check and create if they don't exist.
    )
    # Loop through each specified folder path.
    foreach ($folderPath in $Path) 
    {
        if (-not (Test-Path $folderPath)) 
        {
            try
            {
                # Attempt to create the folder if it doesn't exist.
                mkdir $folderPath | Out-Null
            }
            catch
            {
                # Handle any errors that occur during folder creation.
                Log "Script" "Unable to create the folder [$folderPath] `r`n Error Message :$($_)" 0 Red
                Get-DebugError $_
            }
        }
    }   
}

<# Test-CertThumbprint
.SYNOPSIS
    Verify the existence and validity of a certificate by its thumbprint.

.DESCRIPTION
    This PowerShell function, Test-Certificate, is designed to check if a certificate with a specified thumbprint exists and is valid.
    It can search for certificates in either the "CurrentUser\My" store or the "LocalMachine\My" store.

.PARAMETER Thumbprint
    Specifies the thumbprint of the certificate to be checked. This parameter is mandatory.

.PARAMETER My
    Indicates whether to search for the certificate in the "CurrentUser\My" store. This is an optional switch parameter.

.NOTES
    The function checks for the existence of the certificate, its validity, and provides appropriate logging messages.

.EXAMPLE
    Test-Certificate -Thumbprint "1234567890ABCDEF" -My
    This example checks for the existence and validity of a certificate with the specified thumbprint in the "CurrentUser\My" store.

#>
function Test-CertThumbprint{
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Thumbprint,

        [Parameter(Mandatory=$false, Position=1)]
        [switch]$My
    )

    [System.Security.Cryptography.X509Certificates.X509Certificate2[]]$ValidCertificates = $null

    $StorePath = "*"
    if ($My) {
        $StorePath = "My"
    }

    Log "Script" "`tVerifying the Thumbprint parameter" 1 DarkMagenta

    if (-not [string]::IsNullOrEmpty($Thumbprint)) {
        $Thumbprint = $Thumbprint.ToUpper()
        $ValidCertificates = Get-ChildItem "cert:\*\$StorePath\$Thumbprint" -Recurse -ErrorAction Continue
    }
    else {
        Log "Script" "`t`tThumbprint is empty. Unable to find a matching certificate." 0 Red
        return $false
    }

    if ($ValidCertificates) {
        $ValidNonExpiredCertificates = $ValidCertificates | Where-Object { (Get-Date $_.NotAfter) -gt (Get-Date) }
        $ValidCertificatesPath = ($ValidCertificates | ForEach-Object { ($_.PSPath -split '::')[-1] })

        if ([string]::IsNullOrEmpty($ValidNonExpiredCertificates)) {
            Log "Script" "`t`tOne or more matching certificates have expired:" 0 Red
            $ValidCertificates | ForEach-Object {
                Log "Script" "`t`t    - Thumbprint: $($_.Thumbprint) | Expiry: $($_.NotAfter)" 0 Red
            }

            return $false
        }
        elseif ($ValidNonExpiredCertificates.Count -ge 2) {
            $CurrentUserCertificates = $ValidNonExpiredCertificates | Where-Object { $_.PSPath -like "*CurrentUser\My*" }
            $CurrentUserCertificatesPath = ($CurrentUserCertificates | ForEach-Object { ($_.PSPath -split '::')[-1] })

            if ($CurrentUserCertificates.Count -eq 1) {
                Log "Script" "`t`tOne valid certificate matches the Thumbprint" 1 DarkGreen
                Log "Script" "`t`t    - $Thumbprint found in [$CurrentUserCertificatesPath]" 3 DarkGray
            }
            else {
                Log "Script" "`t`tMultiple valid certificates match the Thumbprint" 1 DarkYellow
                Log "Script" "`t`t    - $Thumbprint found in $($ValidCertificatesPath | ForEach-Object { "`r`n[*" + $_ + "*]" })" 3 DarkGray
            }
        }
        else {
            Log "Script" "`t`tOne valid certificate matches the Thumbprint" 1 DarkGreen
            Log "Script" "`t`t    - $Thumbprint found in [$ValidCertificatesPath]" 3 DarkGray
        }

        return $true
    }
    else {
        if ($My) {
            Log "Script" "`t`tNo matching certificates with Thumbprint: $Thumbprint are installed in the CurrentUser\My store" 0 Red
        }
        else {
            Log "Script" "`t`tNo matching certificates with Thumbprint: $Thumbprint are installed" 0 Red
        }
    }

    return $false
}
<# Test-SpaceFolders
.SYNOPSIS
    Check and manage space usage in specified folders by implementing file rotation.

.DESCRIPTION
    This PowerShell function, Test-SpaceFolders, is designed to check the space usage in specified folders
    and manage their contents to ensure they meet certain criteria, such as maximum size and maximum number of items.
    If a folder exceeds the defined size or item limit, older files are deleted to make room for new ones, effectively
    implementing a file rotation strategy.

.PARAMETER Path
    Specifies an array of folder paths to be checked.

.PARAMETER Keep
    Specifies the maximum number of items (files) to be kept in each folder. Default value is 100.

.PARAMETER Max
    Specifies the maximum size in bytes that each folder should not exceed. Default value is 1MB (1048576 bytes).

.NOTES
    File items are checked in the specified folders, and if a folder exceeds the defined size or item limit, older items
    are deleted to make room for new ones. The function provides detailed logging of its actions, including the files that
    are deleted during rotation.

.EXAMPLE
    Test-SpaceFolders -Path "C:\Logs", "D:\Results" -Keep 50 -Max 5242880
    This example checks the folders "C:\Logs" and "D:\Results," allowing a maximum of 50 items and a maximum size of 5MB (5242880 bytes) for each folder. If the limits are exceeded, older files will be rotated and deleted as needed.

#>
function Test-SpaceFolders {
    param (
        [string[]]$Path,         # An array of folder paths to check.
        [int]$Keep=100,          # Maximum number of items (files) to keep in each folder (100 default).
        [long]$Max=1048576       # Maximum size in bytes each folder should not exceed (1MB default).
    )
    [psobject[]]$AllItems = @()     # Initialize an array to hold all file items across folders.
    [long]$AllItemsSize = 0         # Initialize total size of all items.
    [int]$AllItemsCount = 0         # Initialize total count of all items.

    [int]$FolderCount = $path.Count
    [long]$MaxFolder = $Max / $FolderCount

    foreach ($folderPath in $Path) {
        if ([string]::IsNullOrEmpty($folderPath)){continue}
        [psobject[]]$FolderItems = @()   # Initialize an array to hold file items in the current folder.
        [long]$FolderSize = 0            # Initialize the size of the current folder.
        [int]$FolderCount = 0            # Initialize the count of items in the current folder.

         # Generate a label for the current folder.
        $Folder = "[$(Split-Path $(Split-Path $folderPath -Parent) -leaf)\$(Split-Path $folderPath -Leaf)]"
       

        # Retrieve all files in the folder and check their size.
        Test-Folder $folderPath
        $FolderItems = (get-childitem $folderPath -Recurse) | Where-Object {$_.Attributes -ne "Directory" -and $(split-path $_.DirectoryName -Leaf) -notlike "*error*"} | Select-Object Name,FullName,@{l='size';e={[long]$_.Length}},LastWriteTimeUtc | Sort-Object LastWriteTimeUtc
        $FolderSize = $($FolderItems | Measure-Object -Property size -sum).sum
        $FolderCount = $FolderItems.count
        if ($null -eq $FolderSize){$FolderSize = 0}
        Log "Script" "Size Limit $(WSize $FolderSize)/$(WSize $MaxFolder)`t|  Items Limit $FolderCount/$Keep `t|  $Folder" 2 Cyan

        #Si folder depasse les conditions (defaut : 1Mb et 100 fichiers)
        $i = 0
        if ( $FolderSize -ge $MaxFolder -or $FolderCount -gt $Keep){           
            while ($FolderSize -ge $MaxFolder -or $FolderCount -gt $Keep) {                
                $ItemToDelete = $FolderItems[$i]
                try {
                    Remove-Item $ItemToDelete.FullName -Force -Confirm:$false -ErrorAction Stop
                    $FolderSize -= $ItemToDelete.size 
                    $FolderCount -= 1                  
                    Log "Script" "Deleting [$($ItemToDelete.Name)] - Size Limit $(WSize $FolderSize)/$(WSize $MaxFolder)`t|  Items Limit $FolderCount/$Keep" 3 DarkGray
                }
                catch {
                    # Handle any errors during item deletion.
                    Get-DebugError $_ 
                }
                $i++
            }
           # $i--
        }
        Log "Script" "$i Item(s) deleted" 2 Green
        # Add the folder's items to the total counts.
        $AllItems += $FolderItems
        $AllItemsSize += $FolderSize
        $AllItemsCount += $FolderCount
    }

    return (WSize $AllItemsSize)  # Return the total size of all items.
}


function Test-Administrator {  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    return (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}



function Test-Modules  {
    param (
        [string[]]$modules
    )
    [boolean]$allModule = $true
    foreach ($module in $modules) {
        if ($null -eq (Get-Module "*$module*"))
        {
            $allModule = $false
        }        
    }
    return $allModule
    
}

#endregion TESTING FUNCTION

#############################################################################
############################# MODULES FUNCTION ##############################
#############################################################################

#region MODULES FUNCTION
<# Install-ModuleUserV2
.SYNOPSIS
    Installs or updates a PowerShell module from the PowerShell Gallery.

.DESCRIPTION
    The `Install-ModuleUserV2` function is designed to simplify the installation and update of PowerShell modules from the PowerShell 
    Gallery (PSGallery). It allows you to specify the desired module name, target version, and various options.

.PARAMETER ModuleName
    Specifies the name of the PowerShell module to be installed or updated from PSGallery.

.PARAMETER DesiredVersion
    Specifies the desired version of the module to be installed. If not specified, the latest available version will be installed.

.PARAMETER LatestVersion
    If this switch is used, the function will attempt to install the latest version of the module, regardless of the currently installed version.

.PARAMETER InstallPreview
    If this switch is used, the function will allow the installation of pre-release versions of the module (if available).

.PARAMETER RefreshInstallModule
    If this switch is used, the function will force a reinstallation of the module, even if it is already installed.

.NOTES
    The `Install-ModuleUserV2` function simplifies the management of PowerShell modules by providing a unified interface to install, update, 
    and refresh modules from PSGallery. It handles error conditions, logs actions, and ensures that modules are up to date, giving you a 
    smoother module management experience.

.EXAMPLE
    Install-ModuleUserV2 -ModuleName "AzureRM" -VersionWanted "2.0.0"
    This example installs the "AzureRM" module with the version "2.0.0" from PSGallery.

    Install-ModuleUserV2 -ModuleName "AzureRM" -LatestVersion
    This example installs the latest available version of the "AzureRM" module from PSGallery.

    Install-ModuleUserV2 -ModuleName "MyModule" -InstallPreview
    This example installs the latest pre-release version of the "MyModule" module from PSGallery.

#>
function Install-ModuleUserV2
{
    Param 
    (       
        [Parameter(Mandatory = $true)][string]$ModuleName,
        [Parameter(Mandatory = $false)][version]$DesiredVersion,
        [Parameter(Mandatory = $false)][switch]$LatestVersion,
        [Parameter(Mandatory = $false)][switch]$InstallPreview,
        [Parameter(Mandatory = $false)][switch]$RefreshInstallModule
    )

    [version]$Module_On_PSGalleryVersion = $null

    # Log the action of verifying the module.
    Log "Script" "`tVerifying module [$ModuleName] is installed" 1 DarkMagenta

    if ($DesiredVersion)
    {
        if ($InstallPreview -and $PSVersionTable.PSVersion.Major -ge 7)
        {
            # Find the module on PSGallery with the desired version (including prerelease) if PowerShell 7 or higher.
            $Module_On_PSGallery = Find-Module -Name $ModuleName -AllVersions -AllowPrerelease -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$ModuleName*" } | Select-Object -First 1
            $Module_On_PSGalleryVersion = ($Module_On_PSGallery.Version -split "-")[0]
        }
        else
        {
            # Find the module on PSGallery with the desired version.
            $Module_On_PSGallery = (Find-Module -Name $ModuleName -RequiredVersion $DesiredVersion -ErrorAction SilentlyContinue) | Where-Object { $_.Name -like "*$ModuleName*" -and $null -eq $DesiredVersion -or $DesiredVersion -le $_.Version } | Select-Object -Last 1
            $Module_On_PSGalleryVersion = $Module_On_PSGallery.Version
        }
    }
    else
    {
        if ($InstallPreview -and $PSVersionTable.PSVersion.Major -ge 7)
        {
            # Find the module on PSGallery with the latest prerelease version if PowerShell 7 or higher.
            $Module_On_PSGallery = Find-Module -Name $ModuleName  -AllowPrerelease -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$ModuleName*" } | Select-Object -First 1
            $Module_On_PSGalleryVersion = ($Module_On_PSGallery.Version -split "-")[0]
        }
        else
        {
            # Find the module on PSGallery with the latest version.
            $Module_On_PSGallery = Find-Module -Name $ModuleName -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$ModuleName*" } | Select-Object -First 1
            $Module_On_PSGalleryVersion = $Module_On_PSGallery.Version
        }
    }
    
    if ($LatestVersion -or ($InstallPreview -and $PSVersionTable.PSVersion.Major -ge 7) -and (-not $DesiredVersion))
    {
        # Check if the module with the same version is already installed.
        $Module_On_System = Get-Module -Name $ModuleName -ListAvailable -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$ModuleName*" -and $Module_On_PSGalleryVersion -eq $_.Version}
    }
    else
    {
        # Check if the module with the same version is already installed.
        $Module_On_System = Get-Module -Name $ModuleName -ListAvailable -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$ModuleName*" -and $Module_On_PSGalleryVersion -eq $_.Version} 
    }

    if (([string]::IsNullOrEmpty($Module_On_System)) -and ([string]::IsNullOrEmpty($Module_On_PSGallery))) 
    {            
        # Log that the module doesn't exist or can't be found.
        Log "Script" "`t`tModule [$ModuleName] does not exist or cannot be found" 1 DarkRed
        Get-DebugError $_ 1
        break
    }

    $Installed = $false
    if ((-not ($Module_On_System)) -or $RefreshInstallModule) # If not installed or refresh is requested.
    {
        try
        {
            # Log the installation action.
            Log "Script" "`t`tInstalling module [$ModuleName] - Version [$($Module_On_PSGallery.Version)] " 1 Yellow
            
            if ($InstallPreview -and $PSVersionTable.PSVersion.Major -ge 7)
            {                
                # Install the module with prerelease support if PowerShell 7 or higher.
                Install-Module $ModuleName -RequiredVersion $Module_On_PSGallery.Version -Scope CurrentUser -Confirm:$false -Force -AllowPrerelease -SkipPublisherCheck -AcceptLicense -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null
            }
            else
            {
                # Install the module.
                Install-Module $ModuleName -RequiredVersion $Module_On_PSGallery.Version -Scope CurrentUser -Confirm:$false -Force -SkipPublisherCheck -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null
            }
            Log "Script" "`t`tInstalling module [$ModuleName] - Successfully" 2 Green
            $Installed = $true
            Start-Sleep 1             
        }
        catch
        {
            # Log the error if installation fails.
            Log "Script" "$($_.InvocationInfo.ScriptLineNumber) - Error - Unable to install the module" 1 Red 
            Get-DebugError $_ 1
        }
    }
    else
    {
        # Log that the module is already installed.
        Log "Script" "`t`t$('Module [{0}] (v{1}) is already installed.' -f $ModuleName, $Module_On_System.Version)" 2 DarkGreen
    }

    if (($Module_On_System.Version -ne $Module_On_PSGallery.Version ) -and ($Module_On_System.Version -ne $Module_On_PSGalleryVersion) -and $Installed -eq $false)  # If installed but not up to date.
    {
        try
        {            
            # Log that a new update is found.
            Log "Script" "`t`tNew update found - Updating..." 2 Yellow
            Log "Script" "`t`tUpdating from version [$($Module_On_System.Version)] to version [$Module_On_PSGalleryVersion]" 1 DarkYellow
            
            if ($InstallPreview -and $PSVersionTable.PSVersion.Major -ge 7)
            {                
                # Update the module with prerelease support if PowerShell 7 or higher.
                Install-Module $ModuleName -RequiredVersion $Module_On_PSGallery.Version -Scope CurrentUser -Confirm:$false -Force -AllowPrerelease -SkipPublisherCheck -AcceptLicense -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null
            }
            else
            {
                # Update the module.
                Install-Module $ModuleName -RequiredVersion $Module_On_PSGallery.Version -Scope CurrentUser -Confirm:$false -Force -SkipPublisherCheck -AcceptLicense -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null
            }
            Log "Script" "`t`Updating module [$ModuleName] - Successfully" 2 Green
        }
        catch
        {
            # Log the error if update fails.
            Log "Script" "$($_.InvocationInfo.ScriptLineNumber) - Error - Unable to update the module" 1 Red 
            Get-DebugError $_ 1
        }
    }
}

<# Import-ModuleUserV2
    .SYNOPSIS
    Import a module with specified options.
    
    .DESCRIPTION
    This function imports a PowerShell module with various options, including specifying a desired version,
    installing the latest version, installing preview versions, and refreshing installed modules.
    
    .PARAMETER ModuleName
    The name of the module to import.

    .PARAMETER DesiredVersion
    Specify a desired version of the module. (Optional)

    .PARAMETER LatestVersion
    Import the latest version of the module. (Optional)

    .PARAMETER InstallPreview
    Install preview versions of the module. (Optional)

    .PARAMETER RefreshInstallModule
    Force refresh and install the module. (Optional)

    .EXAMPLE
    Import-ModuleUserV2 -ModuleName "MyModule" -VersionVoulu "1.2.3"
    Import a specific version of the "MyModule" module.

    .EXAMPLE
    Import-ModuleUserV2 -ModuleName "MyModule" -LatestVersion
    Import the latest version of the "MyModule" module.

    .EXAMPLE
    Import-ModuleUserV2 -ModuleName "MyModule" -InstallPreview
    Install the latest preview version of the "MyModule" module.

    .EXAMPLE
    Import-ModuleUserV2 -ModuleName "MyModule" -RefreshInstallModule
    Force refresh and install the "MyModule" module.
#>
function Import-ModuleUserV2
{
    Param 
    (       
        [Parameter(Mandatory = $true)][string]$ModuleName,
        [Parameter(Mandatory = $false)][version]$DesiredVersion,
        [Parameter(Mandatory = $false)][switch]$LatestVersion,
        [Parameter(Mandatory = $false)][switch]$InstallPreview,
        [Parameter(Mandatory = $false)][switch]$RefreshInstallModule
    )

    [version]$Module_On_PSGalleryVersion = $null

    # Logging: Verifying the module.
    Log "Script" "`tVerifying module [$ModuleName] is imported" 1 DarkMagenta

    if ($DesiredVersion)
    {
        if ($InstallPreview)
        {
            # Finding the module on PSGallery with all versions including prereleases.
            $Module_On_PSGallery = Find-Module -Name $ModuleName -AllVersions -AllowPrerelease -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$ModuleName*" } | Select-Object -First 1
            $Module_On_PSGalleryVersion = ($Module_On_PSGallery.Version -split "-")[0]
        }
        else
        {
            # Finding the module on PSGallery with required version or higher.
            $Module_On_PSGallery = Find-Module -Name $ModuleName -RequiredVersion $DesiredVersion -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$ModuleName*" -and $null -eq $DesiredVersion -or $DesiredVersion -le $_.Version } | Select-Object -Last 1
            $Module_On_PSGalleryVersion = $Module_On_PSGallery.Version
        }
    }
    else
    {
        if ($InstallPreview)
        {
            # Finding the module on PSGallery, including prereleases.
            $Module_On_PSGallery = Find-Module -Name $ModuleName  -AllowPrerelease -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$ModuleName*"} | Select-Object -First 1
            $Module_On_PSGalleryVersion = ($Module_On_PSGallery.Version -split "-")[0]
        }
        else
        {
            # Finding the module on PSGallery without prereleases.
            $Module_On_PSGallery = Find-Module -Name $ModuleName -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$ModuleName*"} | Select-Object -First 1
            $Module_On_PSGalleryVersion = $Module_On_PSGallery.Version
        }
    }
    
    if ($LatestVersion -or $InstallPreview -and (-not $DesiredVersion))
    {
        # Checking if the module is already installed with the same version as on PSGallery.
        $Module_On_System = Get-Module -Name $ModuleName -ListAvailable -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$ModuleName*" -and $Module_On_PSGalleryVersion -eq $_.Version}
    }
    else
    {
        # Checking if the module is already installed with the same version as on PSGallery.
        $Module_On_System = Get-Module -Name $ModuleName -ListAvailable -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$ModuleName*" -and $Module_On_PSGalleryVersion -eq $_.Version} 
    }

    if (([string]::IsNullOrEmpty($Module_On_System)) -and ([string]::IsNullOrEmpty($Module_On_PSGallery))) 
    {            
        # Logging: Module does not exist or cannot be found.
        Log "Script" "`t`t$('Module [{0}] is not exist or cannot be found..' -f $ModuleName)" 1 DarkRed
        Get-DebugError $_ 1
        break
    }

     $VersionToLoad = $Module_On_PSGalleryVersion    
    if ([string]::IsNullOrEmpty((Get-Module | Where-Object {($_.Name -eq "$ModuleName" -and $_.Version -eq $VersionToLoad)}))) # if installed but not imported
    {
        if (-not [string]::IsNullOrEmpty($VersionToLoad))
        {
            # Importing the module with the specified version.
            Import-Module $ModuleName -RequiredVersion $VersionToLoad -Force -Global -WarningAction SilentlyContinue | Out-Null
            Log "Script" "`t`t$('Module [{0}] (v{1}) is being loaded.' -f $ModuleName, [string]$VersionToLoad)" 2 DarkYellow
        }
        else
        {
            # Importing the module without specifying a version.
            Import-Module $ModuleName -Force -Global -WarningAction SilentlyContinue  | Out-Null
            Log "Script" "`t`t$('Module [{0}] (v{1}) is being loaded.' -f $ModuleName, [string]$VersionToLoad)" 2 DarkYellow
        }
    }
    else
    {
        # Logging: Module is already loaded.
        Log "Script" "`t`t$('Module [{0}] (v{1}) is already loaded.' -f $ModuleName, $Module_On_System.Version)" 2 DarkGreen
    }
}

function Import-GraphModuleInduviduals () {
    param(
        [Parameter(Mandatory)]
        [ArgumentCompleter({
                param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
                $Global:AllMsGraphModule
        })]
        [ValidateScript({[bool]($Global:AllMsGraphModule -match $_)})]
        [string[]]$ModuleNecessaire,
        
        [Parameter(Mandatory=$false)]
        [version]$DesiredVersion,

        [Parameter(Mandatory=$false)]
        [switch]$AllowPreview = $false
    )

    foreach ($item in $ModuleNecessaire) {
        $ModulOK = ($Global:AllMsGraphModule -match $item | Sort-Object | Select-Object -First 1)
        if ($ModulOK) {
            if ($DesiredVersion)
            {
                Import-ModuleUserV2 $ModulOK -DesiredVersion $DesiredVersion 
            }
            else
            {
                Import-ModuleUserV2 $ModulOK -LatestVersion -InstallPreview:$AllowPreview 
            }
        }else{
            # En cas d'erreur sur le chargement des modules, on arrete
            Log "Script" "A problem occurred when loading modules $item" 1 Yellow
        }
    }
    
}

<#
    .SYNOPSIS
    Install specified Microsoft Graph modules.
    
    .DESCRIPTION
    This function installs specified Microsoft Graph modules individually, allowing the installation of preview versions.

    .PARAMETER ModuleNecessaire
    The list of Microsoft Graph modules to be installed.

    .PARAMETER DesiredVersion
    Specify a desired version of the module. (Optional)

    .PARAMETER AllowPreview
    Install preview versions of the modules. (Optional)
    
    .EXAMPLE
    Install-GraphModuleIndividuals -ModuleNecessaire "Authentication","Sites"
    Install specified Microsoft Graph modules individually.
#>
function Install-GraphModuleInduviduals () {
    param(
        [Parameter(Mandatory)]
        [ArgumentCompleter({
                param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
                $Global:AllMsGraphModule
        })]
        [ValidateScript({[bool]($Global:AllMsGraphModule -match $_)})]
        [string[]]$ModuleNecessaire,
        
        [Parameter(Mandatory=$false)]
        [version]$DesiredVersion,
        
        [Parameter(Mandatory=$false)]
        [switch]$AllowPreview = $false
    )

    foreach ($item in $ModuleNecessaire) {
        $ModulOK = ($Global:AllMsGraphModule -match $item | Sort-Object | Select-Object -First 1)
        if ($ModulOK) {
            if ($DesiredVersion)
            {
                Install-ModuleUserV2 $ModulOK -DesiredVersion $DesiredVersion 
            }
            else
            {
                Install-ModuleUserV2 $ModulOK -LatestVersion -InstallPreview:$AllowPreview 
            }
        }else{
            # En cas d'erreur sur le chargement des modules, on arrete
            Log "Script" "A problem occurred when loading modules $item" 1 Yellow
        }
    }
}


<# Test-PackageProvider 
.SYNOPSIS
    Verify the presence and version of a package provider and update it if necessary.

.DESCRIPTION
    The `Test-PackageProvider` function is used to check the presence and version of a package provider in PowerShell. 
    It can install the provider if it's not already installed and update it if a newer version is available.
    
.PARAMETER Name
    Specifies the name of the package provider to verify and manage.

.NOTES
    The `Test-PackageProvider` function is helpful for ensuring that the required package provider is available and up to date 
    for package management tasks. It checks the provider's version, installs it if missing, and updates it when a newer version 
    is available.

.EXAMPLE
    Test-PackageProvider -Name NuGet
    This example calls the `Test-PackageProvider` function to verify the presence and version of the "NuGet" package provider. 
    If the provider is not installed or is an older version, the function will install or update it accordingly.

#>
Function Test-PackageProvider {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    
    try {
        Log "Script" "`tVerifying provider [$Name]" 1 DarkMagenta
        $InstallPP = Get-PackageProvider -Name $Name -ErrorAction SilentlyContinue
        $InternetPP = Find-PackageProvider -Name $Name -ErrorAction SilentlyContinue

        if ($InstallPP) {
            if ($InstallPP.Version -lt $InternetPP.Version) {
                Log "Script" "`t`tUpdating provider [$Name]" 1 Yellow
                Install-PackageProvider -Name $Name -Force -Scope CurrentUser -Confirm:$false | Out-Null
            } else {
                Log "Script" "`t`tProvider [$Name] is already installed" 2 Green
                
            }
        } else {
            Log "Script" "`tInstalling provider [$Name]" 1 Yellow
            Install-PackageProvider -Name $Name -Force -Scope CurrentUser -Confirm:$false | Out-Null
        }
    } catch {
        Log "Script" "Error - Installing Package Provider [$name]." 1 Red
        Log "Script" "Run Command bellow in admin Powershell :" 1 Red
        Log "Script" "`tInstall-PackageProvider -Name $name -Force" 1 Red
        Get-DebugError $_
        throw 
    }
    
}
#endregion MODULES FUNCTION

#############################################################################
############################## OUTPUT FUNCTION ##############################
#############################################################################

#region OUTPUT FUNCTION
<# WSize
.SYNOPSIS
    Convert a numeric size value into a human-readable format.

.DESCRIPTION
    The `WSize` function is used to convert a numeric size value into a human-readable format, making it easier to understand. It 
    takes a size value (in bytes) and optionally rounds it to a specified number of digits after the decimal point. It then 
    returns the size value in a user-friendly format, such as Terabytes (TB), Gigabytes (GB), Megabytes (MB), Kilobytes (KB), or 
    bytes (Octets).

.PARAMETER size
    Specifies the size value to be converted into a human-readable format (in bytes).

.PARAMETER digit
    Specifies the number of digits after the decimal point to round the size value. The default value is `2`.

.NOTES
    The `WSize` function is a helpful utility for displaying file sizes in a more comprehensible way. It is often used in scripts 
    or programs to present file size information to users in a user-friendly format.

.EXAMPLE
    WSize -size 10485760 -digit 1
    This example calls the `WSize` function to convert a size value of `10485760` bytes into a human-readable format with one 
    decimal digit. The function returns "10.0 MB" as the result, making the size easier to understand.

#>
Function WSize {
    Param ($size,$digit = 2)
    if ($($size / 1TB) -ge 1){
        return "$([math]::Round(($size / 1TB),$digit)) To"
    }elseif ($($size / 1GB) -ge 1){
        return "$([math]::Round(($size / 1GB),$digit)) Go"
    }elseif ($($size / 1MB) -ge 1){
        return "$([math]::Round(($size / 1MB),$digit)) Mo"
    }elseif ($($size / 1024) -ge 1){
        return "$([math]::Round(($size / 1024),$digit)) Ko"
    }else{
        return "$size Octet"
    }
}

Function WDate {
    Param (
        $dateW,
        [Parameter(Mandatory = $true)][ValidateSet("Day","Hour","Minute","Second")]
        [string]$typeInput,
        [Parameter(Mandatory = $false)][ValidateSet("Max","Day","Hour","Minute","Second")]
        [string]$typeOutput = "Max"
    )
    switch ($typeInput) {
        "Day" {
            $TimeSpan = New-TimeSpan -Days $dateW
        }
        "Hour" {
            $TimeSpan = New-TimeSpan -Hours $dateW
        }
        "Minute" {
            $TimeSpan = New-TimeSpan -Minutes $dateW
        }
        "Second" {
            $TimeSpan = New-TimeSpan -Seconds $dateW
        }
        Default {return $dateW}
    }

    if ($TimeSpan.Days -ge 1){
        $dStr = "$($TimeSpan.Days) Days"
    }else{
        $dStr = ""
    }
    if ($TimeSpan.Hours -ge 1){
        $hStr = "$($TimeSpan.Hours) h"
    }else{
        $hStr = ""
    }
    if ($TimeSpan.Minutes -ge 1){
        $mStr = "$($TimeSpan.Minutes) min"
    }else{
        $mStr = ""
    } 
    if ($TimeSpan.Seconds -ge 1){
        $sStr = "$($TimeSpan.Seconds) sec"
    }else{
        $sStr = ""
    }
switch ($typeOutput) {
    "Day" { return "$dStr"  }
    "Hour" { return "$dStr $hStr"  }
    "Minute" { return "$dStr $hStr $mStr "  }    
    "Second" { return "$dStr $hStr $mStr $sStr"  }
    "Max" { return "$dStr $hStr $mStr $sStr"  }
    Default {}
}
    

}

function Show-Param {
    param (
       $LesParam,
       [switch]$lesreturn
    )
    $tab = ""
    $lesKey = $LesParam.keys
    Log "Script" "`t(Debug) Parameter send to the script :" 2 yellow 
    foreach ($key in $lesKey) {            
        Log "Script" "`t`t- $key = $($LesParam.$key)" 2 yellow     
        if ($lesreturn){$tab += "$key = $($LesParam.$key)<br>"}        
    }    
    if ($lesreturn){return $tab}       
}

function Show-ProgressLibrary($Items,$maxItems,$RefreshInterval = 30, $texte="Processing...") 
        {
            if($Items -eq $maxItems){
                Write-Progress -Activity "End Process" -Status "Finish" -PercentComplete 100 -Completed
                return 0
            }
            $currentTime = Get-Date
            if ($currentTime -gt ($Global:previousTime.AddSeconds($RefreshInterval))) {
                $Global:previousTime = $currentTime;

                Write-Progress -Activity "$texte" -Status "[$Items/$maxItems]" -PercentComplete $(($Items) / $maxItems * 100) 
                return 0
            }
            return 1
        }

Function New-CSVFile {
    param (
        $Table,
        $FilePath,
        $FileName
    )

    try{
        if ($Table){
            $Table.Where({ $null -ne $_ -and $_ -ne ""}) | Export-Csv -Path "$($FilePath)\$FileName" -Delimiter ";" -Encoding UTF8 -NoTypeInformation
            Log "Script" "CSV generated : [$FileName]" 2 Green
        }else{
            New-Item -Path $FilePath -Name $FileName -ItemType File | Out-Null
            Log "Script" "No result, but the file was generated : [$FileName]" 2 Yellow
            Log "Script" "`tOccure when no items in all the libraries match the criteria" 3 Yellow
        }
    }catch{
        Log "Script" "Error - Line  [$($_.InvocationInfo.ScriptLineNumber)] - A problem occurred when generating the file : [$FileName]" 0 Red
        Log "Script" "Error - Message : $($_.Exception.Message)" 1 Red
    }
}

function SendMail {
    param (
        [Parameter(Mandatory=$false)][string]$FromMail= $FromMail,
        [Parameter(Mandatory=$false)][string]$ToMail= $ToMail,
        [Parameter(Mandatory=$true)][string]$MailSubject,
        [Parameter(Mandatory=$true)][string]$MailBody,
        [Parameter(Mandatory=$false)][string]$Attachments
    )
    $MailBody += "<p>Script send this mail at $(Get-Date)</p>"
    $params = @{
        Message = @{
            Subject = "$MailSubject"
            Body = @{
                ContentType = "HTML"
                Content = "$MailBody"
            }
            ToRecipients = @(
                @{
                    EmailAddress = @{
                        Address = "$ToMail"
                    }
                }
            )
            Importance = "High"
        }
        
    }
    if ($Attachments) {
        if (test-path $Attachments){
            $attach = Get-Item $Attachments
            $Base64 = [convert]::ToBase64String((Get-Content -path $attach.FullName -Encoding byte))
            $params.Message += @{
                Attachments = @(
                    @{
                        "@odata.type" = "#microsoft.graph.fileAttachment"
                        Name = $attach.Name
                        ContentType = "text/plain"
                        ContentBytes =  $Base64
                    }
                )
            }
        }
    }
   
   
        
    try {       
        Send-MgUserMail -UserId $FromMail -BodyParameter $params -ErrorAction Stop
        Log "Script" "Mail Sent succefully to $ToMail" 1 Green
    } catch { 
        Log "Script" "Erreur - Impossible d'envoyer le mail `r`n`t $($_.InvocationInfo.ScriptLineNumber) - Message d'erreur : $($_)" 0 Red
        Get-DebugError $_
        Disconnect-MsGraphTenant
        exit 1   
    } 
}

$Global:cssMailGeneral = @'

<style>
  body {
      background-color: Gainsboro;
  }

  table, th, td{
    border: 1px solid;
  }
  table {
    min-height: .01%;
    overflow-x: auto;
    width: 100%;
    max-width: 100%;
  }

  h1{
      background-color:Tomato;
      color:white;
      text-align: center;
  }
</style>
'@
#endregion OUTPUT FUNCTION

#############################################################################
######################### AUTHENTIFICATION FUNCTION #########################
#############################################################################

#region AUTHENTIFICATION FUNCTION
<# Connect-MsGraphTenant
    .SYNOPSIS
    Connect to the Microsoft Graph API using the specified information.

    .DESCRIPTION
    This function connects to the Microsoft Graph API using the provided client, tenant, and certificate information. You can also enable 
    TLS 1.2 if needed.

    .PARAMETER ClientId
    The client ID of the Azure AD application that will connect to Microsoft Graph.

    .PARAMETER TenantId
    The Azure AD tenant ID to which you want to connect.

    .PARAMETER CertificateThumbprint
    The thumbprint of the certificate used for authentication.

    .PARAMETER UseTls12
    Use this switch to enable TLS 1.2 support during the connection.

    .EXAMPLE
    Connect-MsGraphTenant -ClientId "yourClientId" -TenantId "yourTenantId" -CertificateThumbprint "yourThumbprint" -UseTls12

    This command connects to Microsoft Graph using the specified client, tenant, and certificate information. It also enables TLS 1.2 for 
    the connection.

#>
function Connect-MsGraphTenant {
    param (
        [Parameter(Mandatory=$false)][string]$ClientId = $ClientId,
        [Parameter(Mandatory=$false)][string]$TenantId = $TenantId,
        [Parameter(Mandatory=$false)][string]$CertThumbprint = $CertThumbprint,
        [Parameter(Mandatory=$false)][switch]$UseTls12
    )

    ## Unloading the 365 module and logging out 
    try
    { 
        Log "Script" "Connecting to the MsGraph API" 2 DarkMagenta

        if ($UseTls12) {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        }

        Connect-MgGraph -ClientId $ClientId -TenantId $TenantId -CertificateThumbprint $CertThumbprint -ErrorAction Stop | Out-Null
        Log "Script" "Successful connection to the MsGraph API" 2 DarkGreen
    }
    catch 
    {
        Log "Script" "Error - Unable to connect to tenant" 0 Red
        Log "test" "
        clientId = $ClientId
        TenantId = $TenantId
        CertThumbprint = $CertThumbprint
        " 99 Red
        Get-DebugError $_ 0
        throw $_.exception.message
    }
}

function Disconnect-MsGraphTenant {
    param (
        [string]$Position ="",
        $Type
    )	
    # Unloading the 365 module and logging out 
    try{
        Log "Script" "$($Position)Disconnecting from the MsGraph API" 2 DarkMagenta           
        Disconnect-MgGraph -ErrorAction Stop  | Out-Null
        Log "Script" "$($Position)Successful disconnection from the MsGraph API" 1 DarkGreen
    } 
    catch 
    {
        if ($Type -eq "Silently"){return 1}
        Log "script" "Error - Unable to disconnect from the MsGraph API" 1 Red
        Get-DebugError $_
        return 1

    }
}

#endregion AUTHENTIFICATION FUNCTION


<#
         Microsoft.Graph.Authentication      #Connect-MgGraph, Disconnect-MgGraph, Get-MgContext, Get-MgProfile...
         Microsoft.Graph.Users               #Get-MgUser, Get-MgUserCreatedObject, Get-MgUserDirectReport, Get-MgUserExtension...
         Microsoft.Graph.Sites               #Add-MgSiteContentTypeCopy, Add-MgSiteContentTypeCopyFromContentTypeHub, Add-MgSiteListConte...
         Microsoft.Graph.ManagedTenants      #Get-MgTenantRelationshipManagedTenant, Get-MgTenantRelationshipManagedTenantAggregatedPolic... 
         Microsoft.Graph.Mail                #Get-MgUserInferenceClassification, Get-MgUserInferenceClassificationOverride, Get-MgUserMai... 
         Microsoft.Graph.Notes               #Get-MgGroupOnenoteNotebook, Get-MgGroupOnenoteNotebookSection, Get-MgGroupOnenoteNotebookSe... 
         Microsoft.Graph.PersonalContacts    #Get-MgUserContact, Get-MgUserContactExtension, Get-MgUserContactFolder, Get-MgUserContactFo...
         Microsoft.Graph.People              #Get-MgUserActivityStatistics, Get-MgUserLastSharedMethodInsight, Get-MgUserPerson, Get-MgUs... 
         Microsoft.Graph.Groups              #Add-MgGroupDriveListContentTypeCopy, Add-MgGroupDriveListContentTypeCopyFromContentTypeHub,... 
         Microsoft.Graph.Financials          #Get-MgFinancial, Get-MgFinancialCompany, Get-MgFinancialCompanyAccount, Get-MgFinancialComp... 
         Microsoft.Graph.Identity            #Complete-MgDirectoryImpactedResource, Complete-MgDirectoryRecommendation, Complete-MgDirect...
         Microsoft.Graph.Planner             #Get-MgGroupPlanner, Get-MgGroupPlannerPlan, Get-MgGroupPlannerPlanBucket, Get-MgGroupPlanne...
         Microsoft.Graph.Teams               #Add-MgChatMember, Add-MgTeamChannelMember, Add-MgTeamMember, Add-MgTeamPrimaryChannelMember... 
         Microsoft.Graph.WindowsUpdates      #Add-MgWindowsUpdatesDeploymentAudienceExclusionMemberById, Add-MgWindowsUpdatesDeploymentAu... 
         Microsoft.Graph.SchemaExtensions    #Get-MgSchemaExtension, New-MgSchemaExtension, Remove-MgSchemaExtension, Update-MgSchemaExte...
         Microsoft.Graph.Reports             #Confirm-MgAuditLogSignInCompromised, Confirm-MgAuditLogSignInSafe, Get-MgAuditLogDirectoryA... 
         Microsoft.Graph.Search              #Add-MgExternalConnectionItemActivity, Get-MgExternal, Get-MgExternalConnection, Get-MgExter... 
         Microsoft.Graph.Security            #Add-MgSecurityCaseEdiscoveryCaseCustodianHold, Add-MgSecurityCaseEdiscoveryCaseNoncustodial... 
         Microsoft.Graph.CloudCommunications #Add-MgCommunicationCallLargeGalleryView, Clear-MgCommunicationPresence, Clear-MgCommunicati... 
         Microsoft.Graph.ChangeNotifications #Get-MgSubscription, Invoke-MgReauthorizeSubscription, New-MgSubscription, Remove-MgSubscrip... 
         Microsoft.Graph.Compliance          #Add-MgComplianceEdiscoveryCaseCustodianHold, Add-MgComplianceEdiscoveryCaseNoncustodialData...
         Microsoft.Graph.DeviceManagement    #Compare-MgDeviceManagementIntent, Compare-MgDeviceManagementTemplate, Compare-MgDeviceManag... 
         Microsoft.Graph.Devices             #Get-MgPrint, Get-MgPrintConnector, Get-MgPrintOperation, Get-MgPrintPrinter...}
#>