## The *Check-BitLocker.ps1* PowerShell Script

This script queries Active Directory for computer objects, checks their BitLocker recovery keys, and sends an email 
alert if any computers are missing recovery keys. It uses the Microsoft Graph API to send email notifications.

## Parameters
```powershell
.\Check-BitLocker\Check-BitLocker.ps1 [[-VerboseLvl] <Byte>] [[-AllowPreview] <Boolean>] [[-AllowBeta] 
<Boolean>] [<CommonParameters>]

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
-AllowPreview <Boolean>
    Obligatoire :                         false
    Position :                            2
    Valeur par défaut                     False
    Accepter l entrée de pipeline :       false
    Accepter les caractères génériques :  false
```
```powershell
-AllowBeta <Boolean>
    Obligatoire :                         false
    Position :                            3
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
This JSON file contains configurations for a script. It is structured into three sections: Generic, Tenant and Script. Find more explanation[here](/Powershell/README.md)
#### Script
- OUBase : This parameter is the OU computers for check if BitLocker recovery keys are available.
- ComputerToExclude : This parameter permit multiple value, for exclude computer form the check

This JSON file is used to configure a script with these specific parameters. It is used to customize the script's behavior according to the user's needs and requirements.


## Example
```powershell
PS> .\Check-BitLocker.ps1

```

## Example
```powershell
PS> .\Check-BitLocker.ps1 -VerboseLvl 2

```

## Notes
This script is designed to help administrators ensure that BitLocker recovery keys are available for all computers, 
providing an alert mechanism when keys are missing.

This PowerShell script performs the following tasks:
1. Sets up the necessary environment and configuration, including loading required modules.
2. Retrieves a list of computer objects from Active Directory that are enabled and within the specified search base.
3. Iterates through the list of computers, excluding those with specific criteria (e.g., names containing "DESKTOP").
4. Checks if each computer has a BitLocker recovery password by querying Active Directory.
5. If a computer doesn't have a recovery password, it's marked as missing one, and details are logged.
6. If any computers are found to be missing recovery keys, an email notification is sent using the Microsoft Graph API.
7. The script logs the outcome, including any sent email notifications, and its execution time.

>Author = 'AUBRIL Damien'

>Creation Date : 26/10/2023

>Version : 1.0

## Related Links
https://github.com/Webi-Time/Scripts/blob/main/Powershell/.Documentation/Check-BitLocker.md

https://github.com/Webi-Time/Scripts/blob/main/Powershell/.Scripts/Check-BitLocker/Check-BitLocker.ps1

## Source Code
```powershell


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
    
                [string]$base = $Script_Param.OUBase
                [string[]]$exceptionList = $Script_Param.ComputerToExclude

        #endregion JSON Config

        #region Modules
            
            try{
                Write-Output "Loading Modules"
                Import-Module -Name ModuleGenerics -Force -ErrorAction Stop
                Import-Module -Name ActiveDirectory -Force -ErrorAction Stop
                
                Test-PackageProvider "NuGet" 
                Test-PackageProvider "PowerShellGet"    

                $ModulesList = "Authentication","Users.Actions"
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

        try{
            Log "Script" "Retrieving the computer list" 1 Cyan
            $list_computers = Get-ADComputer -Filter {(Enabled -eq $True)} -SearchBase $base -SearchScope Subtree -Property msTPM-OwnerInformation, msTPM-TpmInformationForComputer, PasswordLastSet
        }
        catch{
            Log "Script" "Error - Unable to retrieve computer list from OnPremise AD" 1 Red
            Get-DebugError $_
            exit 1
        }
        $strToReport = ""
        $msg = ""
        $found=$false
        foreach ($computer in $list_computers) {
    
            if (($computer.DistinguishedName -match "DESKTOP") -or $exceptionList.Contains($computer.name)) { 
                continue 
            }
    
            [string]$BitLocker_Key = ""
                
            #Check if the computer object has had a BitLocker Recovery Password
            $Bitlocker_Object = Get-ADObject -Filter {objectclass -eq 'msFVE-RecoveryInformation'} -SearchBase $computer.DistinguishedName -Properties 'msFVE-RecoveryPassword' | Select-Object -Last 1
    
            if($Bitlocker_Object.'msFVE-RecoveryPassword') {
                $BitLocker_Key = $BitLocker_Object.'msFVE-RecoveryPassword'
            }
            else {
                $strToReport = "<b>" +$computer.name + "</b>"+ ", no recovery key for laptop with last Password set :" + $computer.PasswordLastSet
                $msg = $msg + "<li>" + $strToReport + "</li>" 
                $found=$true
           }
          }
    
        if ($found)
        {
            Disconnect-MsGraphTenant -Type Silently | Out-Null
            Connect-MsGraphTenant -ClientId $clientId -TenantId $tenantId -CertThumbprint $CertThumbprint
    
            [string]$ObjectMessage = "SCRIPT - Alert - Cannot found Bitlocker key for computers"
            [string]$BodyMessage = "$cssGeneral" + "<h1>List of hosts :</h1><ul>" + $msg + "</ul><br>Please check if excepion list is updated on Visual Cron job"
  
            try{
                SendMail -FromMail $FromMail -ToMail $ToMail -MailSubject $ObjectMessage -MailBody $BodyMessage
                Write-Output "Mail sent - Computer without Bitlocker foud"
                Log "Script" "Mail sent - Computer without Bitlocker foud" 2 Yellow
            } catch { 
                Log "Script" "Error - Unable to send mail" 1 Red
                Get-DebugError $_
                Disconnect-MsGraphTenant
                exit 1
            }	     
        
            ########## END SCRIPT #########
            Disconnect-MsGraphTenant
        } else {
            Log "Script" "Mail not sent - No computer without bitlocker" 2 Green
            Write-Output "Mail not sent - No computer without bitlocker"
        }
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

