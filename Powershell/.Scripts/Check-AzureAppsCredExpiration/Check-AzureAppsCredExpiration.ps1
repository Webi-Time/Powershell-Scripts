<# 
.SYNOPSIS
    Checks and reports the expiration status of Azure Application credentials and sends email alerts for expired or expiring 
    credentials.

.DESCRIPTION
    This PowerShell script checks the expiration status of credentials for Azure Applications and sends email alerts if any 
    of the credentials are expired or set to expire soon. It leverages the Microsoft Graph API for Azure Application data 
    retrieval and email notifications.

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
    - LimitExpirationDays : This parameter is set to "90" and indicates the number of days before expiration for sending an e-mail alert.

.OUTPUTS
    This script generates logging information and may send email alerts for expired or expiring Azure Application credentials.

.EXAMPLE
    PS> .\Check-AzureAppsCredExpiration.ps1 -VerboseLvl 0

.EXAMPLE
    PS> .\Check-AzureAppsCredExpiration.ps1 -VerboseLvl 2

.LINK
    https://github.com/Webi-Time/Scripts/blob/main/Powershell/.Documentation/Check-AzureAppsCredExpiration.md
    https://github.com/Webi-Time/Scripts/blob/main/Powershell/.Scripts/Check-AzureAppsCredExpiration/Check-AzureAppsCredExpiration.ps1

.NOTES
    This script is designed to help Azure administrators proactively manage and monitor Azure Application credentials, 
    ensuring that no credentials expire without notice.

    This PowerShell script performs the following tasks:
        1. Sets up the necessary environment and configuration, including loading required modules.
        2. Retrieves information about Azure Applications, their credentials, and ownership using the Microsoft Graph API.
        3. Identifies credentials that are expired or set to expire soon based on the specified time frame.
        4. Generates HTML-formatted email content with details of expired and expiring credentials.
        5. Sends email alerts for expired or expiring Azure Application credentials.
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
    
                [string]$LimitExpirationDays = $Script_Param.LimitExpirationDays
                

    
        #endregion JSON Config

        #region Modules
            
            try{
                Write-Output "Loading Modules"
                Import-Module -Name ModuleGenerics -Force -ErrorAction Stop
                
                Test-PackageProvider "NuGet" 
                Test-PackageProvider "PowerShellGet"    

                $ModulesList = "Authentication","Applications","Users.Actions"
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
            $Apps = Get-MgApplication -All -PageSize 500
        }
        catch{
            Log "Script" "Unable to retrieve application information" 1 Red
            Get-DebugError $_
            Disconnect-MsGraphTenant
            exit 1
        }
    
    
        $today = Get-Date
        $credentials = @()
    
        $Apps | ForEach-Object{
            try{       
                $aadAppObjId = $_.Id
                $nameApp = $_.DisplayName
                $app = Get-MgApplication -ApplicationId $aadAppObjId 
                $owner = Get-MgApplicationOwner -ApplicationId $aadAppObjId
            }
            catch{
                Log "Script" "Unable to retrieve information from [$nameApp] application" 1 Red
                Get-DebugError $_
                continue
            }
    
    
            $app.KeyCredentials | ForEach-Object{
                $credentials += [PSCustomObject] @{
                    DisplayName = $app.DisplayName;
                    CredentialType = "KeyCredentials (Certificates)";
                    StartDate = $_.StartDateTime;
                    ExpiryDate = $_.EndDateTime;
                    Expired = if(([DateTime]$_.EndDateTime) -lt $today) { "Yes" }else{"No"};
                    ExpireSoon = if(([DateTime]$_.EndDateTime) -lt (Get-Date).AddDays($LimitExpirationDays)) { "Yes" }else{"No"};
                    ExpireIn = "$([int]$(([DateTime]$_.EndDateTime) - (Get-Date)).TotalDays) days";
                    Type = $_.Type;
                    Usage = $_.Usage;
                    Owners = $owner.AdditionalProperties.userPrincipalName;
                    }
            }
    
            $app.PasswordCredentials | ForEach-Object{
                $credentials += [PSCustomObject] @{
                    DisplayName = $app.DisplayName;
                    CredentialType = "PasswordCredentials (Client Secret)";                
                    StartDate = $_.StartDateTime;
                    ExpiryDate = $_.EndDateTime;
                    Expired = if(([DateTime]$_.EndDateTime) -lt $today) { "Yes" }else{"No"};
                    ExpireSoon = if(([DateTime]$_.EndDateTime) -lt (Get-Date).AddDays($LimitExpirationDays)) { "Yes" }else{"No"};
                    ExpireIn = "$([int]$(([DateTime]$_.EndDateTime) - (Get-Date)).TotalDays) days";
                    Type = 'NA';
                    Usage = 'NA';
                    Owners = $owner.AdditionalProperties.userPrincipalName;
                }
            }
        }
        
    
        $credentialsExpired = $credentials | Where-Object {$_.Expired -eq "Yes"} 
        $credentialsExpireSoon = $credentials | Where-Object {$_.Expired -eq "No" -and $_.ExpireSoon -eq "Yes"}
        
        $SendMail = $False
        $body = ""
        if([string]::IsNullOrEmpty($credentialsExpired)) {
             $body += "<h1>Expired certificates :</h1>  <h2>None !</h2> "
        }
        else {
            $body += $credentialsExpired | ConvertTo-Html -Fragment -PreContent "<h1>Expired certificates :</h1>"
            $SendMail = $true
        }
        if([string]::IsNullOrEmpty($credentialsExpireSoon)) {
            $body += "<h1>Certificates expire soon :</h1> <h2>None !</h2> "
        }
        else {
            $body += $credentialsExpireSoon | ConvertTo-Html -Fragment -PreContent "<h1>Certificates expire soon :</h1>"
            $SendMail = $true
        }
    
        if ($SendMail){

    
            Log "Script" "Expired or expiring credentials have been found... " 1 Yellow
            [string]$ObjectMessage = "Credential Azure App expire soon !"
            [string]$BodyMessage = ConvertTo-Html -head $Global:cssMailGeneral -Body $body
    
            try{
                SendMail -FromMail $FromMail -ToMail $ToMail -MailSubject $ObjectMessage -MailBody $BodyMessage
                Write-Output "Mail sent - Application Expire soon"
                Log "Script" "Mail sent - Application Expire soon" 2 Yellow
            } catch { 
                Log "Script" "Error - Unable to send mail" 1 Red
                Get-DebugError $_
                Disconnect-MsGraphTenant
                exit 1
            }
        }else{
            Write-Output "Mail not sent - None Application Expire soon"
        }

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


