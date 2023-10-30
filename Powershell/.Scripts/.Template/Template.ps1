<# 
.SYNOPSIS

.DESCRIPTION

.PARAMETER VerboseLvl
    Verbosity level for logging information. By default, it's set to 1.
        - `0`: Minimal logging. Only critical errors are displayed.
        - `1`: Basic logging. Displays basic information and errors.
        - `2`: Standard logging. Displays standard log messages, basic information, and errors.
        - `3`: Verbose logging. Displays detailed log messages, standard information, and errors.

.PARAMETER AllowPreview
    If set to $true, the script will allow the installation of preview versions of Microsoft Graph modules. By default, it's set to $false.

.PARAMETER AllowBeta
    If set to $true, the script will allow the installation of beta versions of Microsoft Graph modules. By default, it's set to $false.

.INPUTS
    None.

.OUTPUTS

.EXAMPLE

.LINK
    https://github.com/Webi-Time/Powershell-Scripts/blob/main/Powershell/.Documentation/Template.md
    https://github.com/Webi-Time/Powershell-Scripts/blob/main/Powershell/.Scripts/Template/Template.ps1
    
.NOTES
    Author = 'AUBRIL Damien'
    Creation Date : 26/10/2023
    Version : 1.0

#>

[cmdletbinding()]
Param
(
    [Parameter(Mandatory = $false)]
    [ValidateSet(0, 1, 2, 3)]
    [byte]$VerboseLvl = 2,
    
    [Parameter(mandatory=$false)]
    [switch]$AllowPreview = $false,
    
    [Parameter(mandatory=$false)]
    [switch]$AllowBeta = $false
)

Begin
{
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
                #[string]$Path_Result = $null 
                [string]$Path_Result = $Path_Root + "\Results\"

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
                [string]$tenantName      = $Tenant_Param.tenantName
             
            # Variables du script
                [string]$FromMail       = $Script_Param.Mail.FromMail
                [string]$ToMail         = $Script_Param.Mail.ToMail
  
        #endregion JSON Config

        #region Modules
            
            try{
                Write-Output "Loading Modules"
                Import-Module -Name ModuleGenerics -Force -ErrorAction Stop
                
                Test-PackageProvider "NuGet" 
                #Test-PackageProvider "PowerShellGet"

                $GraphModulesList =  "Authentication","Users","Groups","Mail","Calendar","Reports","Identity.DirectoryManagement" 
                #$OthersModulesList = "ExchangeOnlineManagement","MSOnline"
                if(-not (Test-Modules ($GraphModulesList + $OthersModulesList)))
                {
                    if($AllowBeta){
                        [string[]]$Global:AllMsGraphModule = (Find-Module "Microsoft.Graph*").Name
                    }else{
                        [string[]]$Global:AllMsGraphModule = (Find-Module "Microsoft.Graph*").Name | Where-Object {$_ -notlike "*beta*"}
                    }
                    if ($PSVersionTable.PSVersion -like "7.*")
                        {
                            throw "Ne fonctionne pas avec Powershell 7"
                        }
                    else{$vrs =  $null; $vrsExOn =  $null; $vrsMsol = '1.1.183.66' } 
                    Install-GraphModuleInduviduals $GraphModulesList -AllowPreview $false -DesiredVersion $vrs
                    Import-GraphModuleInduviduals $GraphModulesList -AllowPreview $false -DesiredVersion $vrs
                    
                    #Install-ModuleUserV2 "ExchangeOnlineManagement" -DesiredVersion $vrsExOn
                    #Import-ModuleUserV2 "ExchangeOnlineManagement" -DesiredVersion $vrsExOn

                    #Install-ModuleUserV2 "MSOnline" -DesiredVersion $vrsMsol
                    #Import-ModuleUserV2 "MSOnline" -DesiredVersion $vrsMsol
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
}
Process
{
#region Process
    try 
    {
        Log "Script" "Start of script : $($MyInvocation.MyCommand.Name)" 99 Cyan  
        
     






         
        # Deconnexion au cas ou mais sans erreur a afficher
        Disconnect-MsGraphTenant -Type Silently | Out-Null
        Connect-MsGraphTenant -ClientId $clientId -TenantId $tenantId -CertThumbprint $CertThumbprint
 
        
    }
    catch {
        Get-DebugError $_
        exit 1
    }
#endregion Process
}
End
{
#region End
    try{
       
        Log "Script" "END" 0 red
        $Temps = ((Get-Date )-(Get-Date $StartScript)).ToString().Split('.')[0]
        Log "Script" "Running time : " 1 Cyan -NoNewLine ;  Log "Script" "[$($Temps.Split(':')[0])h$($Temps.Split(':')[1])m$($Temps.Split(':')[2])s]" 1 Red -NoDate
        Log "Script" "Script end : " 1 Cyan -NoNewLine ;  Log "Script" "[$($MyInvocation.MyCommand.Name)]" 1 Red -NoDate
       
        #Set-Location $oldLocation
        exit 0
    }
    catch {
        Get-DebugError $_
        exit 1
    }
#endregion End
}
