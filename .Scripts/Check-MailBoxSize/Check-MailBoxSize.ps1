<# 
.SYNOPSIS
    Checks mailbox sizes for users and sends email alerts for users whose mailbox size exceeds a specified threshold.

.DESCRIPTION
    This PowerShell script checks the sizes of user mailboxes and sends email alerts when a user's mailbox size exceeds a 
    specified threshold. It leverages the Microsoft Graph API to gather mailbox usage details.

.PARAMETER VerboseLvl
    Verbosity level for logging information. By default, it's set to 2.
        - `0`: Minimal logging. Only critical errors are displayed.
        - `1`: Basic logging. Displays basic information and errors.
        - `2`: Standard logging. Displays standard log messages, basic information, and errors.
        - `3`: Verbose logging. Displays detailed log messages, standard information, and errors.

.PARAMETER AllowPreview
    If set to $true, the script will allow the installation of preview versions of Microsoft Graph modules. By default, it's
     set to $false.

.PARAMETER AllowBeta
    If set to $true, the script will allow the installation of beta versions of Microsoft Graph modules. By default, it's
     set to $false.

.INPUTS
    - seuilMailAlert : This parameter is set to "50GB" and indicates the size threshold for sending an e-mail alert.

.OUTPUTS
    This script generates logging information and may send email alerts for users with mailbox sizes exceeding the specified 
    threshold.

.EXAMPLE
    PS> .\Check-MailBoxSize.ps1 -VerboseLvl 2
    
.EXAMPLE
    PS> .\Check-MailBoxSize.ps1 -VerboseLvl 2

.LINK
    https://github.com/Webi-Time/Scripts/blob/main/Powershell/.Documentation/Check-MailBoxSize.md
    https://github.com/Webi-Time/Scripts/blob/main/Powershell/.Scripts/Check-MailBoxSize/Check-MailBoxSize.ps1

.NOTES
    This script checks mailbox sizes for users and sends email alerts when a user's mailbox size exceeds a specified threshold. 
    It uses the Microsoft Graph API for data retrieval and email notifications.
    This script is designed to help administrators monitor mailbox sizes and proactively address potential storage issues.

    This PowerShell script performs the following tasks:
        1. Sets up the necessary environment and configuration, including loading required modules.
        2. Retrieves mailbox usage details for users using the Microsoft Graph API.
        3. Identifies users whose mailbox size exceeds a specified threshold.
        4. Generates an email alert with details of users whose mailbox sizes exceed the threshold.
        5. Sends email alerts for users whose mailbox sizes exceed the threshold.
        6. The script logs the outcome, including any sent email notifications, and its execution time.

    Author = 'AUBRIL Damien'
    Creation Date : 26/10/2023
    Version : 1.0
#>

[cmdletbinding()]
Param
(
    [Parameter(Mandatory = $false)][ValidateSet(0, 1, 2, 3, 4, 5)]
    [byte]$VerboseLvl = 2,

    [Parameter(mandatory=$false)]
    [boolean]$AllowPreview = $false,
    
    [Parameter(mandatory=$false)]
    [boolean]$AllowBeta = $false
)


#region Begin
    try{
        Clear-Host
        $StartScript = Get-Date
        if($VerboseLvl -ne 0){Write-host "$(Get-Date -f 'dd/MM/yyyy HH:mm:ss') - Script start : " -f Cyan -NoNewline; Write-host "[$($MyInvocation.MyCommand.Name)]" -f Red}
        $ErrorActionPreference = 'Stop'

        #region Script Variables

            # Get the script name without the .ps1 extension
                [string]$ScriptName = ($($MyInvocation.MyCommand.Name) -split ".ps1")[0]

            # Set the root path of the script
                [string]$Path_Root = $PSScriptRoot

            # Create the path for script log files
                [string]$global:Path_Logs = $Path_Root + "\Logs\"

            # Create the path for script result files
                [string]$Path_Result = $null # $Path_Root + "\Results\"

            # Get the date in "yyyy-MM-dd-HH-mm-ss" format for log files
                [string]$global:Date_Logs_File = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
                        $global:VerboseLvl = $VerboseLvl
        #endregion Script Variables

        #region JSON Config

            # Path to JSON configuration files
                [string]$File_Config = $Path_Root + "\*.json"

            # Load JSON configuration from the file
                [PSCustomObject]$Params = Get-Content $File_Config -Raw | ConvertFrom-Json
                
                [PSCustomObject]$Generic_Param = $Params.Generic
                [PSCustomObject]$Tenant_Param =  $Params.Tenant
                [PSCustomObject]$Script_Param =  $Params.Script

            # Get configuration values for files to keep and maximum space
                [int]$FilesToKeep = $Generic_Param.FilesToKeep
                [long]$SpaceMax = Invoke-Expression $($Generic_Param.SpaceToUseByScriptsMax)

                [string]$clientId        = $Tenant_Param.clientId
                [string]$tenantId        = $Tenant_Param.tenantId
                [string]$CertThumbprint  = $Tenant_Param.clientCertificate
             
            # Variables du script
                [string]$FromMail       = $Script_Param.Mail.FromMail
                [string]$ToMail         = $Script_Param.Mail.ToMail
    
                [string]$seuilMail = Invoke-Expression $($Script_Param.seuilMailAlert)
                

                [string]$Periode = "D90"
                [string]$CsvPath = $Path_Root
                [string]$CsvFile = "Tmp-ReportMailboxUsageDetail-$Periode-$(Get-Date -Format 'yyyy_MM_dd-hh_mm_ss').csv"
            
        #endregion JSON Config

        #region Modules
            
            try{
                Write-Output "Loading Modules"
                Import-Module -Name ModuleGenerics -Force -ErrorAction Stop
                
                Test-PackageProvider "NuGet" 
                Test-PackageProvider "PowerShellGet"    

                $ModulesList = "Authentication","Reports","Users.Actions"
                if(-not (Test-Modules  $ModulesList))
                {
                    if($AllowBeta){
                        [string[]]$Global:AllMsGraphModule = (Find-Module "Microsoft.Graph*").Name
                    }else{
                        [string[]]$Global:AllMsGraphModule = (Find-Module "Microsoft.Graph*").Name | Where-Object {$_ -notlike "*beta*"}
                    }
                    $vrs = $null 
                    Install-GraphModuleInduviduals $ModulesList -AllowPreview $false -DesiredVersion $vrs
                    Import-GraphModuleInduviduals $ModulesList -AllowPreview $false -DesiredVersion $vrs
                    
                }
                if(-not (Test-CertThumbprint $CertThumbprint -My)){throw "Problem with thumbprint in JSON file"}

            }
            catch 
            {                
                Write-Output $_.Exception.Message
                exit 1
            }

        #endregion Modules

        #region function
      
        #endregion function

        
        #region Script Prerequisites

            Show-Param -LesParam $PSBoundParameters

            # Calculate the space used by log and result folders and check if it's within the specified limit
            $SpaceUsed = Test-SpaceFolders ($global:Path_Logs,$Path_Result) $FilesToKeep $SpaceMax
            Log "Script" "$ScriptName - use $SpaceUsed of $(WSize $SpaceMax) limit" 2 Cyan

        #endregion Prerequisites
        
    }
    catch 
    {
        Get-DebugError $_ 
        exit 1
    }
    
#endregion Begin

#region Process
    try 
    {
        Log "Script" "Start of script : $($MyInvocation.MyCommand.Name)" 99 Cyan  

        Disconnect-MsGraphTenant -Type Silently | Out-Null        
        Connect-MsGraphTenant -ClientId $clientId -TenantId $tenantId -CertThumbprint $CertThumbprint
        
        try{
            Log "Script" "Retrieve storage used by users in a temporary CSV file" 1 Cyan
            Get-MgReportMailboxUsageDetail -Period $Periode -OutFile "$($CsvPath)\$CsvFile" -ErrorAction Stop
            [psobject]$Csv = Import-Csv -Path "$($CsvPath)\$CsvFile" -Delimiter ',' -Encoding UTF8
            [psobject]$CsvTrie = ($Csv | Where-Object {[int64]($_.'Storage Used (Byte)') -gt $seuilMail})        
        }
        catch{
            Log "Script" "Error - Unable to retrieve storage used by users" 1 Red
            Get-DebugError $_
            Disconnect-MsGraphTenant
            exit 1
        }

        try 
        { 
            Log "Script" "Deleting the temporary CSV file" 2 Cyan
            Remove-Item -Path "$($CsvPath)\$CsvFile" -Confirm:$false
        } 
        catch 
        {
            Log "Script" "Error - Unable to delete temporary CSV file" 1 Red  
            Get-DebugError $_
        } 

        if ($CsvTrie)
        {
            [string]$ObjectMessage = "SCRIPT - Warning - Mailbox size more than $(wsize $seuilMail)"
            [string]$ContentAlert = $($CsvTrie | Sort-Object @{e={$_.'Storage Used (Byte)' -as [int]}} -Descending | Select-Object @{l="User";e={$_.'User Principal Name'}},@{l="StorageUsed";e={ wsize $_.'Storage Used (Byte)'}} | ConvertTo-Html -As Table -Fragment)
            [string]$BodyMessage = "$cssMailGeneral" + "
                <h1>Users reaching saturation point:</h1> <br>
                $ContentAlert
            "
                                    
            Log "Script" "Mailboxes larger than $(wsize $seuilMail) have been found.." 1 Red
            try{
                log "Test" "$BodyMessage" 55 
                SendMail -FromMail $FromMail -ToMail $ToMail -MailSubject $ObjectMessage -MailBody $BodyMessage
                
                Write-Output "Users Found - Mail sent successfully"
                Log "Script" "Mail sent successfully" 2 Yellow
            } catch { 
                Log "Script" "Error - Unable to send mail" 1 Red
                Get-DebugError $_
                Disconnect-MsGraphTenant
                exit 1
            }	        
        }else{
            Log "Script" "No mailbox has reached the $seuilMail limit" 1 Green 
            Write-Output "No mailbox has reached the $seuilMail limit"
        }

        ########## END SCRIPT #########
        Disconnect-MsGraphTenant
    }
    catch {
        Get-DebugError $_
        exit 1
    }
#endregion Process

#region End
    try{

        $Temps = ((Get-Date )-(Get-Date $StartScript)).ToString().Split('.')[0]
        Log "Script" "Running time : " 1 Cyan -NoNewLine ;  Log "Script" "[$($Temps.Split(':')[0])h$($Temps.Split(':')[1])m$($Temps.Split(':')[2])s]" 1 Red -NoDate
        Log "Script" "Script end : " 1 Cyan -NoNewLine ;  Log "Script" "[$($MyInvocation.MyCommand.Name)]" 1 Red -NoDate

        exit 0
    }
    catch {
        Get-DebugError $_
        exit 1
    }
#endregion End

