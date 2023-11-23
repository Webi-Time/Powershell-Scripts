## You must place the module in one of the appropriate locations before running the scripts
##      - C:\Users\<USERS>\Documents\WindowsPowerShell\Modules\
##      - C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules\


#New-Item -Path "E:\Script Nas" -ItemType SymbolicLink -Target "\\nas.webi-time.fr\Nas\Perso\3 - Script & Programmation\0 - Exakis-Nelite\"

#New-Item -Path "C:\Users\daubril\Documents\WindowsPowerShell\Modules\ModuleSavencia" -ItemType SymbolicLink -Target "\\nas.webi-time.fr\Nas\Perso\3 - Script & Programmation\0 - Exakis-Nelite\Scripts\.Modules\ModuleSavencia"
#New-Item -Path "C:\Users\daubril\Documents\WindowsPowerShell\Modules\ModuleSavencia" -ItemType SymbolicLink -Target 'E:\Script Nas\Scripts\.Modules\ModuleSavencia\'
#New-Item -Path "C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules\ModuleSavencia" -ItemType SymbolicLink -Target 'E:\Script Nas\Scripts\.Modules\ModuleSavencia\'


#############################################################################
############################# TESTING FUNCTION ##############################
#############################################################################

function Get-MgListAllSites {
    param (
        [string[]]$SiteName = @("*"),
        [string[]]$Property = @("Id")
    )

    [psobject[]]$Script:All_Sites = $null
        
    foreach ($search in $SiteName) 
    {
        $Script:All_Sites += Get-MgSite -all -PageSize 500 -Property $Property | `
                        Where-Object {
                            $_.WebUrl -notlike "*-my.sharepoint.com*" -and 
                            $_.WebUrl -notlike "*.sharepoint.com/Sites/contentTypeHub*" -and
                            $_.WebUrl -like "*.sharepoint.com/Sites*" -and 
                            (Split-Path $_.WebUrl -Leaf).ToLower() -like "*$(($search).ToLower())*" 
                        } | Select-Object $Property -Unique
    }
    $Script:All_Sites = $Script:All_Sites | Select-Object $Property -Unique

    Return $Script:All_Sites
}

function Get-PNPListAllSitesInfo {
    param (
        $Connexion,
        [string[]]$SiteName = @("*"),
        [string]$ClientId,
        [string]$tenantName,
        [string]$CertThumbprint
    )
     
    ## RETRIEVE INFO VIA PNP
    [hashtable]$Script:All_Sites = [ordered]@{}
    [pscustomobject[]]$resTMP = $null
    if ($SiteName -contains "*") {
        $SiteName = '*'
    }
    foreach ($search in $SiteName) 
    {
        $resTMP += $(Get-PnPTenantSite -Detailed -Connection $Connexion | Where-Object {
            $_.Url -notlike "*-my.sharepoint.com*" -and 
            $_.Url -like "*.sharepoint.com/Sites*" -and 
            $_.template -ne 'RedirectSite#0' -and 
            $_.template -ne 'APPCATALOG#0' -and 
            (Split-Path $_.Url -Leaf).ToLower() -like "*$(($search).ToLower())*" 
        } | Select-Object Title,Description,Url,GroupId,HubSiteId,LastContentModifiedDate,Owner,RelatedGroupId,SharingCapability,Status,SensitivityLabel,Template,StorageUsageCurrent)
    }

    # Transforme PNP result to Hastable
    foreach ($SitePNP in  $resTMP ) {
        try {
            $Script:All_Sites +=  [ordered]@{
                $SitePNP.Url = $SitePNP;
            }
        }
        catch {
            <#Do this if a terminating exception happens#>
        }
        
    }
     
    Return $Script:All_Sites
}

function Get-MgListAllSitesInfo {
    param (
        $AllSites
    )
     
    [hashtable]$Script:All_Sites = [ordered]@{}
    
    foreach ($site in $AllSites) {
        try{
            $siteGraph = Get-MgSite -SiteId $site.Id -Property Id,DisplayName,Name,Description,WebUrl,Drive,CreatedDateTime,LastModifiedDateTime -ExpandProperty 'Drive' -ErrorAction Stop
        }catch{
            Log "Script" "Error - Not Found : $($site.DisplayName) | $($site.WebUrl) " 1 Red
            continue
        }

        $Script:All_Sites += [ordered]@{
            $siteGraph.WebUrl = $siteGraph;
        }
    }

    Return $Script:All_Sites
}

function Get-PNPOwners {
    param (
        $Connexion,
        $PNPSite
    )
    [string[]]$owns = @()
    if ($PNPSite.Owner) {
        $owns = (Get-PnPUser -Includes UserId,Title,UserPrincipalName,Email -Connection $Connexion | ? Email -eq $PNPSite.Owner).UserPrincipalName
    }elseif($PNPSite.GroupId) {
        $owns = (Get-PnPMicrosoft365Group -Identity $PNPSite.GroupId -IncludeOwners -Connection $Connexion).Owners.UserPrincipalName # | Where-Object {$null -ne $_} # | % {if($null -eq $_.Email){$_.UserPrincipalName}else{$_.Email}}
    }
    return $owns
}

function Add-ListItemPNP {
    param (        
        $SDAPConnexion,
        $SDAP_List_Name,
        $fields   
    )
    try {
        Log "Script" "Creating item: $($fields.Site_x0020_Name)" 1 Green
        # Attempt to add a new item to the "testSDAP" list
        $null = Add-PnPListItem -List $SDAP_List_Name -Connection $SDAPConnexion -Values $fields 
        Log "Action" "Creating item: $($fields.Site_x0020_Name)" 5  
    }
    catch {
        Log "Script" "ERROR - Error during item creation : $($fields | Out-String -Stream)" 1 Red
        Get-DebugError $_
    }
}

function Update-ListItemPNP {
    param (        
        $SDAPConnexion,
        $SDAP_List_Name,
        $SDAP_List_ItemID,
        $fieldsToUpdate  
    )
    try {
        Log "Script" "Updating item: [$SDAP_List_ItemID] - $($fieldsToUpdate.Site_x0020_Name)" 1 Green
        # Attempt to add a new item to the "testSDAP" list
        Set-PnPListItem -List $SDAP_List_Name -Identity $SDAP_List_ItemID -Connection $SDAPConnexion -Values $fieldsToUpdate 
        Log "Action" "Updating item : [$SDAP_List_ItemID] - $($fieldsToUpdate.Site_x0020_Name)" 5  
    }
    catch {
        Log "Script" "ERROR - Error during item creation : $($fieldsToUpdate | Out-String -Stream)" 1 Red
        Get-DebugError $_
    }
}
