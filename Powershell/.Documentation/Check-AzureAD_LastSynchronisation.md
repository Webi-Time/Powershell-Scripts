## The *Check-AzureAD_LastSynchronisation.ps1* PowerShell Script

This script checks the last synchronization performed by Azure AD Connect and sends an email alert if synchronization 
hasn't occurred within the specified timeframe. It uses the Microsoft Graph API to interact with Azure AD.

## Parameters
```powershell
.\Check-AzureAD_LastSynchronisation\Check-AzureAD_LastSynchronisation.ps1 [[-VerboseLvl] 
<Byte>] [[-AllowBeta] <Boolean>] [<CommonParameters>]

```
```powershell
-VerboseLvl <Byte>
    Obligatoire :                         false
    Position :                            1
    Valeur par défaut                     2
    Accepter l entrée de pipeline :       false
    Accepter les caractères génériques :  false
```
```powershell
-AllowBeta <Boolean>
    Obligatoire :                         false
    Position :                            2
    Valeur par défaut                     False
    Accepter l entrée de pipeline :       false
    Accepter les caractères génériques :  false
```
```powershell
[<CommonParameters>]
    This script supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, 
    WarningVariable, OutBuffer, PipelineVariable, and OutVariable.
```

## Inputs
### JSON configuration
This JSON file contains configurations for a script. It is structured into three sections: Generic, Tenant and Script. Find more explanation [here](/Powershell/README.md)
#### Script
- MaxMinutes : This parameter is set to "45" and indicates the maximum number of minutes without synchronization and e-mail alert.

This JSON file is used to configure a script with these specific parameters. It is used to customize the script's behavior according to the user's needs and requirements.


## Example
```powershell
PS> .\Check-ADConnectSync.ps1 -VerboseLvl 0

```

## Example
```powershell
PS> .\Check-ADConnectSync.ps1 -VerboseLvl 2

```

## Notes
This script checks Azure AD Connect synchronization and sends an email alert if synchronization is interrupted. 
It uses the Microsoft Graph API to interact with Azure AD.

This PowerShell script performs the following tasks:
1. Sets up the necessary environment and configuration, including loading required modules.
2. Retrieves the last synchronization time of Azure AD using the Azure AD Graph API.
3. Compares the last synchronization time with the specified time frame to determine if synchronization is overdue.
4. If synchronization is overdue, it logs the details and sends an email notification using the Microsoft Graph API.
5. The script logs the outcome, including any sent email notifications, and its execution time.

>Author = 'AUBRIL Damien'

>Creation Date : 26/10/2023

>Version : 1.0

## Related Links
https://github.com/Webi-Time/Powershell-Scripts/blob/main/Powershell/.Documentation/Check-AzureAD_LastSynchronisation.md

https://github.com/Webi-Time/Powershell-Scripts/blob/main/Powershell/.Scripts/Check-AzureAD_LastSynchronisation/Check-AzureAD_LastSynchronisation.ps1

## Source Code
```powershell


[cmdletbinding()]
Param
(
    [Parameter(Mandatory = $false)][ValidateSet(0, 1, 2, 3, 4, 5)]
    [byte]$VerboseLvl = 2,

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
    
                [string]$MaxMinutes = $Script_Param.MaxMinutes

        #endregion JSON Config

        #region Modules
            
            try{
                Write-Output "Loading Modules"
                Import-Module -Name ModuleGenerics -Force -ErrorAction Stop
                
                Test-PackageProvider "NuGet" 
                #Test-PackageProvider "PowerShellGet"    

                $GraphModulesList = "Authentication","Identity.DirectoryManagement","Users","Users.Actions"
                #$OthersModulesList = "ExchangeOnlineManagement","MSOnline"
                if(-not (Test-Modules ($GraphModulesList + $OthersModulesList)))
                {
                    if($AllowBeta){
                        [string[]]$Global:AllMsGraphModule = (Find-Module "Microsoft.Graph*").Name
                    }else{
                        [string[]]$Global:AllMsGraphModule = (Find-Module "Microsoft.Graph*").Name | Where-Object {$_ -notlike "*beta*"}
                    }
                    $vrs = $null 
                    Install-GraphModuleInduviduals $GraphModulesList -DesiredVersion $vrs
                    Import-GraphModuleInduviduals $GraphModulesList -DesiredVersion $vrs
                    
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
            function Convert-UTCtoLocal { 
                param( 
                    [parameter(Mandatory=$true)] [DateTime] $UTCTime 
                )
                return [System.TimeZoneInfo]::ConvertTimeFromUtc($UTCTime, (Get-TimeZone)) 
            }
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
       
            Disconnect-MsGraphTenant -Type Silently | Out-Null
            Connect-MsGraphTenant -ClientId $clientId -TenantId $tenantId -CertThumbprint $CertThumbprint
            try{
                [DateTime]$MaxDeltaSync = ((Get-Date).ToUniversalTime())-(New-TimeSpan -Hours 0 -Minutes $MaxMinutes)
                [DateTime]$LastDirSyncTime = (Get-MgOrganization -ErrorAction Stop).OnPremisesLastSyncDateTime  
            }
            catch{
                Log "Script" "Error - Unable to retrieve information on last synchronization" 1 Red
                Get-DebugError $_ 2                
                $errMailAD = "ERROR DETECTED - Unable to retrieve information on last synchronization. Check Log"
                [DateTime]$LastDirSyncTime = [datetime]::new(1)
            }
        
            $RealDate = Convert-UTCtoLocal $LastDirSyncTime
        
            if($LastDirSyncTime -le $MaxDeltaSync)
            {
                [int]$Difference = ($(Get-Date) - $RealDate).TotalHours
                [string]$ObjectMessage = "AZURE AD CONNECT - SYNC IS BROKEN!"
                [string]$BodyMessage = "$cssGeneral <h1> Synchronization issues </h1>  <br>
                AD Connect has not been synchronized for more than $MaxMinutes min.<br>
                The last synchronization was performed : <b>$RealDate</b> ( $(WDate -dateW $Difference -typeInput Hour))<br>$errMailAD"
        
                Log "Script" "Synchronization has not been performed since $RealDate ($(WDate -dateW $Difference -typeInput Hour))"  1 Red
                try{
                    SendMail -FromMail $FromMail -ToMail $ToMail -MailSubject $ObjectMessage -MailBody $BodyMessage
                    Write-Output "Mail sent - Synchronization Warning"
                    Log "Script" "Mail sent - Synchronization Warning" 2 Yellow
                } catch { 
                    Log "Script" "Error - Unable to send mail" 1 Red
                    Get-DebugError $_
                    Disconnect-MsGraphTenant
                    exit 1
                }	        
            }else{
                Log "Script" "La synchronisation a été effectué à $RealDate" 2 Green 
                Log "Script" "Mail not sent - Synchronization OK" 2 Green
                Write-Output "Mail not sent - Synchronization OK"
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



```

