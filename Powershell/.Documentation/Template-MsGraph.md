## The *Template-MsGraph.ps1* PowerShell Script

This script description

## Parameters
```powershell
E:\NAS_Scripts\Github\Scripts\Powershell\.Scripts\.Template-MsGraph\Template-MsGraph.ps1 [[-VerboseLvl] <Byte>] [-AllowBeta] [<CommonParameters>]

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
-AllowBeta [<SwitchParameter>]
    Obligatoire :                         false
    Position :                            named
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
- JSON File with tenant information
- Variable : description

This JSON file is used to configure a script with these specific parameters. It is used to customize the script's behavior according to the user's needs and requirements.


## Example
```powershell
PS> .\script.ps1 -paramater

```

## Notes
Ensure the [ModuleGenerics] module is installed and that you have the necessary permissions to access Azure AD data.

>Author = 'AUBRIL Damien'

>Creation Date : 26/10/2023

>Version : 2.0

>Version Date : 05/09/2024

## Related Links
https://github.com/Webi-Time/Powershell-Scripts/blob/main/Powershell/.Documentation/Template.md

https://github.com/Webi-Time/Powershell-Scripts/blob/main/Powershell/.Scripts/Template/Template.ps1

## Source Code
```powershell
 ##############################################################################
        
 
        #region MAIL
            #region For send EMAIL with Text

                [string]$ObjectMessage = "AZURE AD CONNECT - SYNC IS BROKEN!"
                [string]$BodyMessage = $mailTemplate -replace "!--MAX_ALERT--!" , $MaxMinutes `
                                                    -replace "!--REAL_DATE--!", $RealDate `
                                                    -replace "!--DELTA_DATE--!", $(WDate -dateW $Difference -typeInput Hour) `
                                                    -replace "!--ERROR_MAIL--!", $errMailAD
            #endregion For send EMAIL with Text
            
            #region For send EMAIL with Table
                for ($i = 0; $i -lt 3; $i++) {
                    $Users += [PSCustomObject]@{
                        "Nom d'utilisateur" = "Titi $i"
                        "UPN"               = "titi$i@domain.com"
                        "Option1"           = "option$i"
                    }
                }        
                [string]$ObjectMessage = "User DEFAULT"
                [string]$BodyMessage = $mailTemplate -replace "!--TABLE_USERS--!", $(($Users | Select-Object * | ConvertTo-Html -Fragment -As Table )) `
                                                     -replace "!--ERROR_MAIL--!", $errMailAD
            #endregion For send EMAIL with Table
            try
            {
                if (-not [string]::IsNullOrEmpty($errMailAD)) 
                {
                    $ErrorLogFile = Get-ChildItem "$global:Path_Logs\Error" -Recurse | Where-Object {$_.Name -like "*$($global:Date_Logs_File)*" | Select-Object -First 1} 
                    SendMail -FromMail $FromMail -ToMail $ToMail -MailSubject $ObjectMessage -MailBody $BodyMessage -Attachments $ErrorLogFile.FullName
                    Log "Script" "Mail sent with error - <about mail content>" 2 Yellow
                }
                else
                {
                    SendMail -FromMail $FromMail -ToMail $ToMail -MailSubject $ObjectMessage -MailBody $BodyMessage
                    Log "Script" "Mail sent : <about mail content>" 2 Green
                }
            } 
            catch 
            { 
                Log "Script" "Error - Unable to send mail" 1 Red
                Get-DebugError $_             
            }
        #endregion MAIL

        Disconnect-MsGraphTenant
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
    try
    {
        $Temps = ((Get-Date )-(Get-Date $StartScript)).ToString().Split('.')[0]
        Log "Script" "Running time : " 1 Cyan -NoNewLine ;  Log "Script" "[$($Temps.Split(':')[0])h$($Temps.Split(':')[1])m$($Temps.Split(':')[2])s]" 1 Red -NoDate
        Log "Script" "Script end : " 1 Cyan -NoNewLine ;  Log "Script" "[$($MyInvocation.MyCommand.Name)]" 1 Red -NoDate
       
        #Set-Location $oldLocation
        exit 0
    }
    catch 
    {
        Get-DebugError $_
        exit 1
    }
#endregion End
}


```

