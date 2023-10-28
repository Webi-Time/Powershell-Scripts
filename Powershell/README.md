---
title: "Hello"
author: "AUBRIL Damien"
date: "16 janvier 2023"
output: "html_document"
version: "0.1"
---

<h1 align="center">Scripts de Webi-Time</h1>

<h1>Collection de scripts PowerShell </h1>

<p align="left">Les scripts que vous trouverez dans mon Github ont été développés dans le cadre de missions pour des clients, puis modifiés. Il est important de préciser que certains scripts ont un but bien précis et sont difficilement adaptables. Deplus, la responsabilité n'engage que celui qui utilise le script. J'essaie d'être le plus professionnel possible mais il peut rester des erreurs.</p>




# Configuration JSON

Les fichiers JSON contiennent les configurations pour un script. Chaque script en possede un. Il sont structurés en trois sections : 
- Generic,
- Tenant,
- Script.

## Generic

La section "Generic" comprend des paramètres génériques pour le script. Elle contient deux éléments :
- **FilesToKeep** : Ce paramètre est défini sur "50" et indique le nombre de fichiers à conserver.
- **SpaceToUseByScriptsMax** : Ce paramètre est défini sur "5MB" et indique l'espace maximum autorisé pour les scripts.

## Tenant

La section "Tenant" contient des informations spécifiques au locataire Microsoft. Elle inclut les éléments suivants :
- **clientId** : Identifiant du client, par exemple, "xxx0e736-xxxx-4488-8699-xxxxxxxxxxxx".
- **tenantId** : Identifiant du locataire, par exemple, "xxxxx255-4e75-xxxx-8d64-267xxxxxx242".
- **clientCertificate** : Empreinte du certificat du client, par exemple, "A0B9FBC8A6D556XXXXXXDBD5EABF5114AF1CE3".
- **tenantName** : Nom du locataire, par exemple, "m365x12345678.onmicrosoft.com".

## Script

La section "Script" contient des paramètres spécifiques au script. Elle comporte deux éléments :
- **Mail** : Cette sous-section concerne les paramètres liés à l'envoi d'e-mails. Elle contient les éléments suivants :
  - **FromMail** : Adresse e-mail de l'expéditeur, par exemple, "security.scripts@m365x12345678.onmicrosoft.com".
  - **ToMail** : Adresse e-mail du destinataire, par exemple, "MyEmailAdress@domain.com".
- **seuilMailAlert** : Ce paramètre est défini sur "50GB" et indique le seuil de taille pour envoyer une alerte par e-mail.

This JSON file is used to configure a script with these specific parameters. It is used to customize the script's behavior according to the user's needs and requirements.



<br><br>

# Liste des scripts
---
## ⚙️ Scripts 
| Script | Description |
| -- | -- |
| [Check-AzureAD_LastSynchronisation.ps1](/Powershell/.Scripts/Check-AzureAD_LastSynchronisation/Check-AzureAD_LastSynchronisation.ps1)       | Vérifie la dernière synchronisation Azure AD | 
| [Check-AzureAppsCredExpiration.ps1](/Powershell/.Scripts/Check-AzureAppsCredExpiration/Check-AzureAppsCredExpiration.ps1)    | Vérifie les dates d'expiration des informations d'identification des applications Azure | 
| [Check-BitLocker.ps1](/Powershell/.Scripts/Check-BitLocker/Check-BitLocker.ps1)                                                                | Vérifie l'état de BitLocker sur les ordinateurs |
| [Check-MailBoxSize.ps1](/Powershell/.Scripts/Check-MailBoxSize/Check-MailBoxSize.ps1)                                                          | Vérifie la taille des boîtes aux lettres | 
| [Start-ConnectTenant.ps1](/Powershell/.Scripts/Start-ConnectTenant/Start-ConnectTenant.ps1)                                                    | Établit et gère la connexion au locataire Microsoft | 
|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx|

## 📝 Scripts ...
-----------------------------

| Script | Description | Documentations |
| -- | -- | -- |
| ---------En construction--------- | ---------En construction--------- |
|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx|